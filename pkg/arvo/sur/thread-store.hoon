|%
+$  serial  @uvH
::
+$  uid  [=ship =serial]
::
+$  threads  (map uid thread)
::
+$  fabric  (map path threads)
::
+$  thread
  $:  =config
      packages=(list package)
      indices=(map uid @)
      reply-to=(unit target-post)
  ==
::
+$  config
  $:  length=@
      read=@
  ==
::
+$  package
  $:  =post
      reply-threads=(list uid)
  ==
::
+$  target-post  [thread=uid post=uid]
::
+$  post
  $:  =uid
      author=ship
      when=time
      =container
  ==
::
+$  container
  $%  [%content =content] 
      [%multiple multiple=(list content)]
  ==
::
+$  content
  $%  [%text text=cord]
      [%url url=cord]
      [%udon udon=manx]
      [%blob mime=@t blob=octs]
      ::  maybe [%json =json] if we want to get really crazy
  ==
::
+$  expanded-threads  (map uid expanded-thread)
::
+$  expanded-thread
  $:  =config
      packages=(list expanded-package)
      indices=(map uid @)
      reply-to=(unit target-post)
  ==
::
+$  expanded-package
  $:  =post
      reply-threads=threads
  ==
::
+$  thread-action
  $%  ::  %path: initialize a path to an empty map of uid to thread
      ::
      [%path =path]
      ::  %thread: create a new thread at path
      ::
      [%thread =path =uid =thread]
      ::  %post: if post is last package in list, append to list
      ::  if post is not last package in list, create reply-thread
      ::
      [%post =path =post target=(unit target-post)]
      ::  %delete-path: delete a map at path
      ::
      [%delete-path =path]
      ::  %delete-thread: delete a thread at uid at path
      ::
      [%delete-thread =path =uid]
      ::  %delete-post: delete a thread at path
      ::
      [%delete-post =path target=target-post]
      ::  %read: set thread to read
      ::
      [%read =path thread-uid=uid]
  ==
::
+$  thread-update
  $%  [%keys keys=(set path)]
      [%thread-keys =path keys=(set uid)]
      thread-action
  ==
--
