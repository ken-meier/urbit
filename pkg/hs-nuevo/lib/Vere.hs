module Vere where

import ClassyPrelude

import qualified Data.Map as M
import           Nuevo
import           Program
import           Types

initialVereEnv :: NuevoProgram -> VereEnv
initialVereEnv np = VereEnv { instances = M.singleton TopNodeId firstInstance }
  where
    firstInstance = InstanceThread
      { itEventQueue =
        [ NEvInit
          TopNodeId
          (Path [])
          np
          (IoSocket 0 "base")
          "datum"
        ]
      , itNuevoState = emptyNuevoState
      , itEventLog = []
      }

-- TODO: This isn't the way to handle this long term, but for now, we run over
-- each instance
vereStep :: VereEnv -> IO VereEnv
vereStep ve = do
  let (effects, newEnv) = M.mapAccumWithKey accumExec [] (instances ve)

  print ("env: " ++ (show newEnv))
  print ("effects: " ++ (show effects))

  let x =  (handleNuevoEffect (ProcessNodeId (Path []) 0))
  pure (foldl' x (VereEnv newEnv) effects)


-- | For every instance of nuevo, run one event and accumulate the effects.
accumExec :: [NuevoEffect]
          -> NodeId
          -> InstanceThread
          -> ([NuevoEffect], InstanceThread)
accumExec previousEffects id it@(InstanceThread [] _ _)
  = (previousEffects, it)

accumExec previousEffects id InstanceThread{..}
  = (previousEffects ++ newEffects, newInst)
  where
    (event : restEvents) = itEventQueue
    (newState, newEffects) = runNuevoFunction itNuevoState event
    newInst = InstanceThread
      { itEventQueue = restEvents
      , itNuevoState = newState
      , itEventLog = (0, event):itEventLog
      }


-- Nuevo has given us an effect and we must react to it.
handleNuevoEffect :: NodeId -> VereEnv -> NuevoEffect -> VereEnv
handleNuevoEffect self@(ProcessNodeId (Path path) seq) env = \case
  NEfSend p@(PipeSocket _ _ target) msg ->
    -- This puts a corresponding recv in the mailbox of the counterparty
    enqueueEvent env target (NEvRecv (flipSocket self p) msg)

  -- Sending to an io driver is an IO event; we need to handle this.
  NEfSend (IoSocket id driver) msg -> undefined

  -- Forking a new process
  NEfFork{..} -> env
    { instances = M.insert newNodeId newInstance (instances env)
    }
    where
      -- TODO: Allocate the socket representation here and return to the caller
      -- in case %init passes.
      newNodeId = ProcessNodeId newName 0
      -- TODO: Actually copy the old state
      newInstance = InstanceThread
        { itEventQueue =
          [NEvInit newNodeId newName neForkProgram newProcessSocket neForkMessage]
        , itNuevoState = emptyNuevoState
        , itEventLog = []
        }
      newName = Path (path ++ [neForkName])
      -- TODO: Make a valid socket instead of a dummy value
      newProcessSocket = PipeSocket 5 self self


enqueueEvent :: VereEnv -> NodeId -> NuevoEvent -> VereEnv
enqueueEvent env con event =
  env{instances=newInstances}
  where
    newInstances = M.adjust changeInstance con (instances env)
    changeInstance i@InstanceThread{..} =
      i{itEventQueue = itEventQueue ++ [event]}


flipSocket :: NodeId -> Socket -> Socket
flipSocket self p@PipeSocket{..} = p{pipeCounterparty = self}
flipSocket _    i@IoSocket{..}   = i