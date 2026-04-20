<SKPaymentQueue: 0x14c3e0040>: Error in remote proxy while checking server queue: Error Domain=SKInternalErrorDomain Code=12 "(null)"
[2026-04-20T02:47:24Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T02:47:24Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=39460, exifOrientation=6
[2026-04-20T02:47:24Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=39460
[2026-04-20T02:47:24Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T02:47:24Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T02:47:25Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T02:47:25Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=6, items=["toy_car@89%", "toy_car@95%", "toy_car@64%", "toy_fire_truck@87%", "toy_car@94%", "toy_car@91%"]
[2026-04-20T02:47:25Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=6, items=["toy_car@89%", "toy_car@95%", "toy_car@64%", "toy_fire_truck@87%", "toy_car@94%", "toy_car@91%"]
[2026-04-20T02:47:25Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=6, labels=["toy_car", "toy_car", "toy_car", "toy_fire_truck", "toy_car", "toy_car"]
[2026-04-20T02:47:25Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=49715
[2026-04-20T02:47:25Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=6, blurredBytes=49715
[2026-04-20T02:47:27Z] [DEBUG] [CompanionViewModel.runFullPipeline:339] runFullPipeline: start, mode=cloud, jpegBytes=49715, childAge=6
[2026-04-20T02:47:27Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1014] runCloudPipeline: start, jpegBytes=49715, childAge=6
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 360.0), childAge=6
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 360.0)
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=5, items=["toy_car@95%", "toy_car@96%", "toy_car@83%", "toy_car@96%", "toy_car@94%"]
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:272] Stage 3 – object detection: labels=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"]
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.classifyScene:382] Stage 4 – scene classification: labels=["toy", "vehicle_toy"]
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:399] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.process:142] Pipeline benchmark: faceDetect=5ms blur=3ms yolo=29ms scene=29ms stt=29ms piiScrub=0ms total=43ms
[2026-04-20T02:47:27Z] [DEBUG] [PrivacyPipelineService.process:143] Stage 6 – output: objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"], hasTranscript=false
[2026-04-20T02:47:27Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1024] runCloudPipeline: privacy done, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"], latency=43ms
[2026-04-20T02:47:27Z] [DEBUG] [StoryTimelineStore.insert:42] StoryTimeline: session inserted id=62EF6DFD-9804-4E84-82B0-2102BF2E7F77
[2026-04-20T02:47:27Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=204, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:47:32Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=373
[2026-04-20T02:47:32Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1043] runCloudPipeline: beat[0] received in 4649ms, beatIndex=0
[2026-04-20T02:47:32Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1044] beat[0] storyText: Oh, look at all these colorful toy cars! They seem ready for a big adventure, don't they? Perhaps they're on their way to a super fun playground or even a cozy picnic spot. You get to decide where they go!
[2026-04-20T02:47:32Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1045] beat[0] question: Where do you think these cars are heading right now?
[2026-04-20T02:47:32Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1046] beat[0] isEnding: false
[2026-04-20T02:47:32Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 4 sentence(s), chars=202
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:47:47Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=4, chars=202
[2026-04-20T02:47:47Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=52
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:47:51Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=52
[2026-04-20T02:47:51Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:47:51Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:47:54Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-20T02:47:55Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-20T02:47:55Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-20T02:47:56Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=21, tokensRedacted=0
[2026-04-20T02:47:57Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:47:57Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:47:59Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
Passing along Operation canceled in response to ExecuteRequest
Received ModelManagerError that couldn't be converted to a TokenGenerationError: Operation canceled
Passing along Request D7FE3683-AB14-4BE8-8EDC-5B4DE91C46B4 not found in response to CancelRequest
[2026-04-20T02:47:59Z] [WARNING] [SemanticTurnDetector.semanticCheck:97] listenForAnswer: Layer 2 error (Failed to deserialize a Generable type from model output), treating as complete
[2026-04-20T02:47:59Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:47:59Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1651200
[2026-04-20T02:47:59Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Heading to a playground
[2026-04-20T02:47:59Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Heading to playground', length=21
[2026-04-20T02:47:59Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=519, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:48:03Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=380
[2026-04-20T02:48:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Heading to playground'
[2026-04-20T02:48:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[1] storyText: That's a wonderful idea! The toy cars zoom along, imagining all the swings and slides waiting for them at the playground. They might even see some friendly squirrels collecting acorns on their exciting journey.
[2026-04-20T02:48:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[1] question: What do you think they'll play first when they arrive?
[2026-04-20T02:48:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[1] isEnding: false
[2026-04-20T02:48:03Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=208
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:48:16Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=208
[2026-04-20T02:48:16Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=54
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:48:20Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=54
[2026-04-20T02:48:20Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:48:20Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:48:22Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=1, tokensRedacted=0
[2026-04-20T02:48:22Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-20T02:48:23Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:48:23Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-20T02:48:23Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:48:24Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-20T02:48:24Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=33, tokensRedacted=0
[2026-04-20T02:48:25Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:48:25Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:48:26Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=33, tokensRedacted=0
[2026-04-20T02:48:28Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:48:28Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:48:28Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:48:28Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1497600
[2026-04-20T02:48:28Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=I want to play football with them
[2026-04-20T02:48:28Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='I want to play football with them', length=33
[2026-04-20T02:48:28Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=827, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:48:28Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: Recognition request was canceled
[2026-04-20T02:48:32Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=430
[2026-04-20T02:48:32Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='I want to play football with them'
[2026-04-20T02:48:32Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[2] storyText: Oh, playing football with the toy cars sounds like so much fun, Test Child! You can imagine them rolling a tiny football with their wheels, zooming back and forth across the playground grass. Perhaps they are working together as a team to score a big, exciting goal!
[2026-04-20T02:48:32Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[2] question: What colors are the teams in your football game?
[2026-04-20T02:48:32Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[2] isEnding: false
[2026-04-20T02:48:32Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=264
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:48:50Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=264
[2026-04-20T02:48:50Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=48
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:48:53Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=48
[2026-04-20T02:48:53Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:48:53Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:48:56Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=1, tokensRedacted=0
[2026-04-20T02:48:57Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-20T02:48:57Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:48:58Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-20T02:48:58Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=19, tokensRedacted=0
[2026-04-20T02:48:59Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=22, tokensRedacted=0
[2026-04-20T02:49:00Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=27, tokensRedacted=0
[2026-04-20T02:49:01Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=33, tokensRedacted=0
[2026-04-20T02:49:01Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:49:02Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T02:49:02Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=I want to want them to wear green
[2026-04-20T02:49:02Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='I want to want them to wear green', length=33
[2026-04-20T02:49:02Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1179, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:49:02Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T02:49:04Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=448
[2026-04-20T02:49:04Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='I want to want them to wear green'
[2026-04-20T02:49:04Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[3] storyText: Oh, what a fantastic idea, Test Child! You imagine the toy cars shimmering and changing, each one now a bright, vibrant green! They look like a super speedy, green team, ready to play football and zoom across the soft playground grass. What kind of amazing team do you think they are?
[2026-04-20T02:49:04Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[3] question: What kind of amazing team do you think they are?
[2026-04-20T02:49:04Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[3] isEnding: false
[2026-04-20T02:49:04Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 4 sentence(s), chars=281
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:49:25Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=4, chars=281
[2026-04-20T02:49:25Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=48
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:49:29Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=48
[2026-04-20T02:49:29Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:49:29Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:49:32Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:49:33Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:49:34Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=13, tokensRedacted=0
[2026-04-20T02:49:34Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-20T02:49:35Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:49:35Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-20T02:49:36Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:49:36Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:49:37Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:49:37Z] [WARNING] [SemanticTurnDetector.semanticCheck:97] listenForAnswer: Layer 2 error (The operation couldn’t be completed. (Swift.CancellationError error 1.)), treating as complete
[2026-04-20T02:49:37Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:49:37Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1555200
[2026-04-20T02:49:37Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=They they can beat messy
[2026-04-20T02:49:37Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='They they can beat messy', length=24
[2026-04-20T02:49:37Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1531, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:49:37Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T02:49:40Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=456
[2026-04-20T02:49:40Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='They they can beat messy'
[2026-04-20T02:49:40Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[4] storyText: Oh, you want the speedy green car team to be super good and win, maybe even against someone named Messy! They are zooming with all their might, imagining how to kick the tiny football with their wheels and score lots of goals. I wonder, what kind of special moves do you think they will use to win the game?
[2026-04-20T02:49:40Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[4] question: What special moves will they use?
[2026-04-20T02:49:40Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[4] isEnding: false
[2026-04-20T02:49:40Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=305
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:49:59Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=305
[2026-04-20T02:49:59Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=33
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:50:02Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=33
[2026-04-20T02:50:02Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:50:02Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:50:05Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:50:06Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=8, tokensRedacted=0
[2026-04-20T02:50:07Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T02:50:07Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-20T02:50:08Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:50:08Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:50:09Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-20T02:50:10Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:50:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:50:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:50:10Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T02:50:10Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=They can run fast
[2026-04-20T02:50:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='They can run fast', length=17
[2026-04-20T02:50:10Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1901, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:50:10Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: Recognition request was canceled
[2026-04-20T02:50:13Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=454
[2026-04-20T02:50:13Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='They can run fast'
[2026-04-20T02:50:13Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[5] storyText: Oh, you imagine your green car team zooming incredibly fast, their wheels spinning like blurs on the playground grass! They race past everyone, so quick and nimble, making it super easy for you to get to the tiny football first. You can almost see the wind rushing past them as they zoom.
[2026-04-20T02:50:13Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[5] question: What do you think they're running so fast towards?
[2026-04-20T02:50:13Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[5] isEnding: false
[2026-04-20T02:50:13Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=286
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:50:32Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=286
[2026-04-20T02:50:32Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=50
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:50:36Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=50
[2026-04-20T02:50:36Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:50:36Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:50:40Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:50:41Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T02:50:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:50:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=19, tokensRedacted=0
[2026-04-20T02:50:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-20T02:50:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=26, tokensRedacted=0
[2026-04-20T02:50:43Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=31, tokensRedacted=0
[2026-04-20T02:50:44Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:50:44Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:50:44Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:50:45Z] [WARNING] [SemanticTurnDetector.semanticCheck:97] listenForAnswer: Layer 2 error (The operation couldn’t be completed. (Swift.CancellationError error 1.)), treating as complete
[2026-04-20T02:50:45Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:50:45Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1593600
[2026-04-20T02:50:45Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=They are running to make a goal
[2026-04-20T02:50:45Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='They are running to make a goal', length=31
[2026-04-20T02:50:45Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=2287, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:50:45Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T02:50:49Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=427
[2026-04-20T02:50:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='They are running to make a goal'
[2026-04-20T02:50:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[6] storyText: Yes, you can see them zooming so fast, their little wheels carrying them right up to the tiny football! With a mighty spin and a perfect kick, you imagine the ball flying straight into the goal net, and a big cheer goes up for your amazing, speedy team! They did it!
[2026-04-20T02:50:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[6] question: What do you think your cars do after scoring?
[2026-04-20T02:50:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[6] isEnding: false
[2026-04-20T02:50:49Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=264
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:51:07Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=264
[2026-04-20T02:51:07Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=45
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:51:11Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=45
[2026-04-20T02:51:11Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:51:11Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:51:13Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-20T02:51:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:51:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-20T02:51:15Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:51:16Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:51:16Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:51:17Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:51:18Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:51:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:51:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:51:18Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1363200
[2026-04-20T02:51:18Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=The dance after scoring
[2026-04-20T02:51:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='The dance after scoring', length=23
[2026-04-20T02:51:18Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=2621, keySet=true, objects=["toy_car", "toy_car", "toy_car", "toy_car", "toy_car"], scene=["toy", "vehicle_toy"]
[2026-04-20T02:51:18Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: Recognition request was canceled
[2026-04-20T02:51:25Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=472
[2026-04-20T02:51:25Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='The dance after scoring'
[2026-04-20T02:51:25Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[7] storyText: Oh, after that amazing goal, you imagine your speedy green car team twirling and spinning, doing a joyful victory dance right there on the playground! Their wheels make happy little circles and figure-eights, celebrating their big win together. What a fantastic and speedy game you helped them play today!
[2026-04-20T02:51:25Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[7] question: How do you feel about their happy celebration dance?
[2026-04-20T02:51:25Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[7] isEnding: true
[2026-04-20T02:51:25Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=303
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:51:44Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=303
[2026-04-20T02:51:44Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=52
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:51:49Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=52
[2026-04-20T02:51:49Z] [DEBUG] [StoryTimelineStore.finalizeSession:50] StoryTimeline: session finalised beats=8, restart=false
nw_path_necp_check_for_updates Failed to copy updated result (22)
[2026-04-20T02:52:00Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T02:52:00Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=37483, exifOrientation=6
[2026-04-20T02:52:00Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=37483
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["toy_airplane@95%", "toy_airplane@98%"]
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["toy_airplane@95%", "toy_airplane@98%"]
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["toy_airplane", "toy_airplane"]
[2026-04-20T02:52:00Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=46904
[2026-04-20T02:52:00Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=46904
[2026-04-20T02:52:08Z] [DEBUG] [CompanionViewModel.runFullPipeline:339] runFullPipeline: start, mode=cloud, jpegBytes=46904, childAge=6
[2026-04-20T02:52:08Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1014] runCloudPipeline: start, jpegBytes=46904, childAge=6
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 360.0), childAge=6
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 360.0)
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=1, items=["wardrobe@94%"]
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:272] Stage 3 – object detection: labels=["wardrobe"]
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.classifyScene:382] Stage 4 – scene classification: labels=["container", "cardboard_box", "cord"]
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:399] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.process:142] Pipeline benchmark: faceDetect=5ms blur=3ms yolo=43ms scene=43ms stt=43ms piiScrub=0ms total=55ms
[2026-04-20T02:52:08Z] [DEBUG] [PrivacyPipelineService.process:143] Stage 6 – output: objects=["wardrobe"], scene=["container", "cardboard_box", "cord"], hasTranscript=false
[2026-04-20T02:52:08Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1024] runCloudPipeline: privacy done, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"], latency=55ms
[2026-04-20T02:52:08Z] [DEBUG] [StoryTimelineStore.insert:42] StoryTimeline: session inserted id=98401365-D05F-4210-8F09-A0EA322ED951
[2026-04-20T02:52:08Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=180, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:52:13Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=387
[2026-04-20T02:52:13Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1043] runCloudPipeline: beat[0] received in 4985ms, beatIndex=0
[2026-04-20T02:52:13Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1044] beat[0] storyText: You push open the big wardrobe doors and step inside, feeling the soft carpet under your feet. What a surprise! Inside, you see a sturdy container and a big cardboard box, and a long, colorful cord stretches across the floor.
[2026-04-20T02:52:13Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1045] beat[0] question: What do you think is inside the cardboard box?
[2026-04-20T02:52:13Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1046] beat[0] isEnding: false
[2026-04-20T02:52:13Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=223
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:52:29Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=223
[2026-04-20T02:52:29Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=46
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:52:33Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=46
[2026-04-20T02:52:33Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:52:33Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:52:36Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-20T02:52:36Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-20T02:52:37Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T02:52:37Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-20T02:52:37Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-20T02:52:38Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:52:38Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:52:39Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-20T02:52:40Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:52:40Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:52:40Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:52:40Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1420800
[2026-04-20T02:52:40Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-20T02:52:40Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Can see some coins', length=18
[2026-04-20T02:52:40Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=509, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:52:44Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=395
[2026-04-20T02:52:44Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Can see some coins'
[2026-04-20T02:52:44Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[1] storyText: Wow, what a discovery! You're right, tucked away near the colorful cord are some shiny coins! I wonder if they're hidden inside the sturdy container or maybe peeking out from the big cardboard box. What do you think you should do with them?
[2026-04-20T02:52:44Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[1] question: Where do you think the coins came from?
[2026-04-20T02:52:44Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[1] isEnding: false
[2026-04-20T02:52:44Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 4 sentence(s), chars=237
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:53:00Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=4, chars=237
[2026-04-20T02:53:00Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=39
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:53:03Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=39
[2026-04-20T02:53:03Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:53:03Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:53:09Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-20T02:53:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:53:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:53:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:53:10Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1228800
[2026-04-20T02:53:10Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Space
[2026-04-20T02:53:10Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Space', length=5
[2026-04-20T02:53:10Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=794, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:53:14Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=454
[2026-04-20T02:53:14Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Space'
[2026-04-20T02:53:14Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[2] storyText: Space! What a wonderful idea, Test Child! You look at the shiny coins and suddenly, they twinkle like tiny stars, ready for an amazing journey. Perhaps this big wardrobe isn't just a wardrobe, but a super-secret spaceship, and these coins are special space-fuel for your adventure!
[2026-04-20T02:53:14Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[2] question: Where in space do you think your spaceship will go first?
[2026-04-20T02:53:14Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[2] isEnding: false
[2026-04-20T02:53:14Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 4 sentence(s), chars=278
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:53:34Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=4, chars=278
[2026-04-20T02:53:34Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=57
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:53:39Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=57
[2026-04-20T02:53:39Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:53:39Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:53:41Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-20T02:53:41Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-20T02:53:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:53:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-20T02:53:43Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:53:43Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:53:44Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-20T02:53:45Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:53:45Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:53:45Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:53:45Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1228800
[2026-04-20T02:53:45Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-20T02:53:45Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Go to the Moon', length=14
[2026-04-20T02:53:45Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1151, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:53:49Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=363
[2026-04-20T02:53:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Go to the Moon'
[2026-04-20T02:53:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[3] storyText: To the Moon you go! You buckle up in your super-secret spaceship, feeling the hum of the engine as the special space-fuel coins glow with anticipation. Your moon adventure is about to begin!
[2026-04-20T02:53:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[3] question: What do you see out the window as you start your journey?
[2026-04-20T02:53:49Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[3] isEnding: false
[2026-04-20T02:53:49Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=188
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:54:02Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=188
[2026-04-20T02:54:02Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=57
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:54:06Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=57
[2026-04-20T02:54:06Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:54:06Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:54:11Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=1, tokensRedacted=0
[2026-04-20T02:54:11Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-20T02:54:12Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-20T02:54:13Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T02:54:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-20T02:54:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-20T02:54:14Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:54:14Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T02:54:14Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=I can see demons
[2026-04-20T02:54:14Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='I can see demons', length=16
[2026-04-20T02:54:14Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1412, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:54:17Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=421
[2026-04-20T02:54:17Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='I can see demons'
[2026-04-20T02:54:17Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[4] storyText: Wow, what great noticing! As your spaceship zooms closer to the Moon, you spot some wiggly shapes outside the window! Perhaps they are friendly moon shadows dancing in the starlight, or maybe curious space friends peeking out from behind a glowing star.
[2026-04-20T02:54:17Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[4] question: What do you think these mysterious shapes are doing?
[2026-04-20T02:54:17Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[4] isEnding: false
[2026-04-20T02:54:17Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=251
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:54:34Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=251
[2026-04-20T02:54:34Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=52
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:54:38Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=52
[2026-04-20T02:54:38Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:54:38Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:54:41Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:54:41Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-20T02:54:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-20T02:54:42Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=21, tokensRedacted=0
[2026-04-20T02:54:43Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=22, tokensRedacted=0
[2026-04-20T02:54:43Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-20T02:54:43Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=27, tokensRedacted=0
[2026-04-20T02:54:44Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=35, tokensRedacted=0
[2026-04-20T02:54:44Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=38, tokensRedacted=0
[2026-04-20T02:54:45Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=42, tokensRedacted=0
[2026-04-20T02:54:46Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:54:46Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T02:54:46Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=These mysterious shapes are dancing in the space
[2026-04-20T02:54:46Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='These mysterious shapes are dancing in the', length=42
[2026-04-20T02:54:46Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1786, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:54:51Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=397
[2026-04-20T02:54:51Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='These mysterious shapes are dancing in the'
[2026-04-20T02:54:51Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[5] storyText: You see those wiggly shapes still dancing! They swirl and twirl around a big, sparkly moon rock that looks just like a cozy cardboard box, and a long, glowing cord seems to be their favorite jump rope. Maybe they are having a moon party!
[2026-04-20T02:54:51Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[5] question: What fun game do you think they are playing?
[2026-04-20T02:54:51Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[5] isEnding: false
[2026-04-20T02:54:51Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=235
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:55:07Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=235
[2026-04-20T02:55:07Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=44
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:55:11Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=44
[2026-04-20T02:55:11Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:55:11Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:55:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:55:14Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=8, tokensRedacted=0
[2026-04-20T02:55:16Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:55:16Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:55:16Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-20T02:55:18Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-20T02:55:18Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:55:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:55:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:55:18Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1324800
[2026-04-20T02:55:18Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-20T02:55:18Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='They are', length=8
[2026-04-20T02:55:18Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=2050, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:55:22Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=493
[2026-04-20T02:55:22Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='They are'
[2026-04-20T02:55:22Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[6] storyText: These friendly moon dancers wave at you with their wiggly arms, inviting you to join their space celebration! They love to play hide-and-seek behind the big cardboard box, and the glowing cord makes a perfect circle for a friendly moon ring-around-the-rosy. I wonder what kind of special moon treats they might have!
[2026-04-20T02:55:22Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[6] question: What kind of moon party games do you think they like to play?
[2026-04-20T02:55:22Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[6] isEnding: false
[2026-04-20T02:55:22Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=314
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:55:41Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=314
[2026-04-20T02:55:41Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=61
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:55:46Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=61
[2026-04-20T02:55:46Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:55:46Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:55:53Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:55:54Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:55:54Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:55:54Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:55:54Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1440000
[2026-04-20T02:55:54Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=They pop
[2026-04-20T02:55:54Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='They', length=4
[2026-04-20T02:55:54Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=2419, keySet=true, objects=["wardrobe"], scene=["container", "cardboard_box", "cord"]
[2026-04-20T02:55:54Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T02:56:00Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=500
[2026-04-20T02:56:00Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='They'
[2026-04-20T02:56:00Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[7] storyText: You giggle as the friendly moon dancers offer you a sparkly, warm moon cookie from their cozy cardboard box, shared with a special glow from the cord! After sharing treats and one last quiet game under the stars, it’s time for your spaceship to gently float back towards home, feeling happy and full of moon party memories.
[2026-04-20T02:56:00Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[7] question: What wonderful memories will you carry from this moon party?
[2026-04-20T02:56:00Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[7] isEnding: true
[2026-04-20T02:56:00Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 2 sentence(s), chars=322
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:56:20Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=2, chars=322
[2026-04-20T02:56:20Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=60
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:56:25Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=60
[2026-04-20T02:56:25Z] [DEBUG] [StoryTimelineStore.finalizeSession:50] StoryTimeline: session finalised beats=8, restart=false
[2026-04-20T02:56:58Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T02:56:59Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=53137, exifOrientation=6
[2026-04-20T02:56:59Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=53137
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:169] Stage 2 – face blur: faceCount=1, applying CIGaussianBlur sigma=30
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["bed@94%", "potted_plant@99%"]
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["bed@94%", "potted_plant@99%"]
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["bed", "potted_plant"]
[2026-04-20T02:56:59Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=65083
[2026-04-20T02:56:59Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=65083
[2026-04-20T02:57:10Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T02:57:10Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=53201, exifOrientation=6
[2026-04-20T02:57:10Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=53201
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:169] Stage 2 – face blur: faceCount=1, applying CIGaussianBlur sigma=30
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["bed@91%", "door@93%"]
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["bed@91%", "door@93%"]
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["bed", "door"]
[2026-04-20T02:57:10Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=65651
[2026-04-20T02:57:10Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=65651
[2026-04-20T02:57:16Z] [DEBUG] [CompanionViewModel.runFullPipeline:339] runFullPipeline: start, mode=cloud, jpegBytes=65651, childAge=6
[2026-04-20T02:57:16Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1014] runCloudPipeline: start, jpegBytes=65651, childAge=6
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 380.0), childAge=6
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 380.0)
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:169] Stage 2 – face blur: faceCount=1, applying CIGaussianBlur sigma=30
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=1, items=["sofa@67%"]
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:272] Stage 3 – object detection: labels=["sofa"]
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.classifyScene:382] Stage 4 – scene classification: labels=["structure", "wood_processed", "people"]
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:399] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.process:142] Pipeline benchmark: faceDetect=36ms blur=24ms yolo=166ms scene=166ms stt=166ms piiScrub=0ms total=232ms
[2026-04-20T02:57:16Z] [DEBUG] [PrivacyPipelineService.process:143] Stage 6 – output: objects=["sofa"], scene=["structure", "wood_processed", "people"], hasTranscript=false
[2026-04-20T02:57:16Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1024] runCloudPipeline: privacy done, objects=["sofa"], scene=["structure", "wood_processed", "people"], latency=232ms
[2026-04-20T02:57:16Z] [DEBUG] [StoryTimelineStore.insert:42] StoryTimeline: session inserted id=30C0DCF8-F584-490C-8A21-E5A0F8A104CF
[2026-04-20T02:57:16Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=179, keySet=true, objects=["sofa"], scene=["structure", "wood_processed", "people"]
[2026-04-20T02:57:21Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=418
[2026-04-20T02:57:21Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1043] runCloudPipeline: beat[0] received in 4635ms, beatIndex=0
[2026-04-20T02:57:21Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1044] beat[0] storyText: I wonder if you're building something amazing with that big, comfy sofa! Perhaps you're arranging it just right, and some helpful people are around to share ideas with you. It looks like you're creating a wonderful, cozy structure, maybe even a secret hideout!
[2026-04-20T02:57:21Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1045] beat[0] question: What kind of special place are you making?
[2026-04-20T02:57:21Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1046] beat[0] isEnding: false
[2026-04-20T02:57:21Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=258
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:57:37Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=258
[2026-04-20T02:57:37Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=42
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:57:41Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=42
[2026-04-20T02:57:41Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:57:42Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:57:44Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-20T02:57:45Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=8, tokensRedacted=0
[2026-04-20T02:57:46Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=20, tokensRedacted=0
[2026-04-20T02:57:47Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-20T02:57:48Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-20T02:57:48Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=31, tokensRedacted=0
[2026-04-20T02:57:48Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=31, tokensRedacted=0
[2026-04-20T02:57:48Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
[2026-04-20T02:57:48Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=40, tokensRedacted=0
[2026-04-20T02:57:49Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=48, tokensRedacted=0
[2026-04-20T02:57:50Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:57:50Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1555200
[2026-04-20T02:57:50Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Making a comfortable bed for me to sleep tonight
[2026-04-20T02:57:50Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Making a comfortable bed for me to sleep tonight', length=48
[2026-04-20T02:57:50Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=603, keySet=true, objects=["sofa"], scene=["structure", "wood_processed", "people"]
[2026-04-20T02:57:57Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=401
[2026-04-20T02:57:57Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Making a comfortable bed for me to sleep tonight'
[2026-04-20T02:57:57Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[1] storyText: Oh, what a lovely idea! You're making a super comfy bed for yourself, maybe even the coziest spot in your special hideout. It must feel so soft and warm, perfect for wonderful dreams, especially with the helpful people around!
[2026-04-20T02:57:57Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[1] question: What soft things will you add to make your bed even cozier?
[2026-04-20T02:57:57Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[1] isEnding: false
CoreData: debug: WAL checkpoint: Database did checkpoint. Log size: 1012 checkpointed: 1012
[2026-04-20T02:57:57Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=224
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:58:13Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=224
[2026-04-20T02:58:13Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=59
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:58:17Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=59
[2026-04-20T02:58:18Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:58:18Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:58:24Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=11, tokensRedacted=0
[2026-04-20T02:58:25Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:58:25Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:58:26Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:58:26Z] [WARNING] [SemanticTurnDetector.semanticCheck:97] listenForAnswer: Layer 2 error (The operation couldn’t be completed. (Swift.CancellationError error 1.)), treating as complete
[2026-04-20T02:58:26Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:58:26Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1612800
[2026-04-20T02:58:26Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-20T02:58:26Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Comfortable', length=11
[2026-04-20T02:58:26Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=856, keySet=true, objects=["sofa"], scene=["structure", "wood_processed", "people"]
[2026-04-20T02:58:29Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=443
[2026-04-20T02:58:29Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Comfortable'
[2026-04-20T02:58:29Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[2] storyText: It sounds like you're making sure your new bed is extra, extra comfortable for you! You're creating the perfect soft spot to rest, maybe even with fluffy pillows and warm blankets. All the people around seem to appreciate how comfy your special hideout is becoming.
[2026-04-20T02:58:29Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[2] question: What else could make your cozy spot even more perfect for you?
[2026-04-20T02:58:29Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[2] isEnding: false
[2026-04-20T02:58:29Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=263
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:58:46Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=263
[2026-04-20T02:58:46Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=62
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:58:51Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=62
[2026-04-20T02:58:51Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:58:51Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:58:57Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T02:58:58Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T02:58:58Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T02:58:58Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:58:58Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1363200
[2026-04-20T02:58:58Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Yeah
[2026-04-20T02:58:58Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Yeah', length=4
[2026-04-20T02:58:58Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1171, keySet=true, objects=["sofa"], scene=["structure", "wood_processed", "people"]
[2026-04-20T02:59:03Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=439
[2026-04-20T02:59:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Yeah'
[2026-04-20T02:59:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[3] storyText: You're doing a fantastic job making sure your special bed is the most comfortable spot imaginable! I wonder if you'll add some extra fluffy pillows or a cozy blanket to make it even more perfect for your dreams. All the people around seem to see how comfy it is.
[2026-04-20T02:59:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[3] question: What kind of wonderful dreams do you think you'll have there?
[2026-04-20T02:59:03Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[3] isEnding: false
[2026-04-20T02:59:03Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=260
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:59:20Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=260
[2026-04-20T02:59:20Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=61
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:59:24Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=61
[2026-04-20T02:59:24Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T02:59:24Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T02:59:32Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T02:59:32Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T02:59:32Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T02:59:32Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=nil
[2026-04-20T02:59:32Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='nil', length=0
[2026-04-20T02:59:32Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1097] continueCloudLoop: answer timeout, ending story
[2026-04-20T02:59:32Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 2 sentence(s), chars=126
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T02:59:40Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=2, chars=126
[2026-04-20T02:59:40Z] [DEBUG] [StoryTimelineStore.finalizeSession:50] StoryTimeline: session finalised beats=4, restart=false
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:03:18Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T03:03:18Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=48659, exifOrientation=6
[2026-04-20T03:03:18Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=48659
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["potted_plant@97%", "potted_plant@98%"]
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["potted_plant@97%", "potted_plant@98%"]
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["potted_plant", "potted_plant"]
[2026-04-20T03:03:18Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=61015
[2026-04-20T03:03:18Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=61015
[2026-04-20T03:03:23Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T03:03:23Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=49507, exifOrientation=6
[2026-04-20T03:03:23Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=49507
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["potted_plant@97%", "potted_plant@99%"]
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["potted_plant@97%", "potted_plant@99%"]
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["potted_plant", "potted_plant"]
[2026-04-20T03:03:23Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=61933
[2026-04-20T03:03:23Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=61933
[2026-04-20T03:03:28Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T03:03:28Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=40273, exifOrientation=6
[2026-04-20T03:03:28Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=40273
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["potted_plant@99%", "potted_plant@98%"]
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=2, items=["potted_plant@99%", "potted_plant@98%"]
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=2, labels=["potted_plant", "potted_plant"]
[2026-04-20T03:03:28Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=51039
[2026-04-20T03:03:28Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=2, blurredBytes=51039
[2026-04-20T03:03:35Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T03:03:35Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=51921, exifOrientation=6
[2026-04-20T03:03:35Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=51921
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=3, items=["potted_plant@98%", "potted_plant@98%", "potted_plant@95%"]
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=3, items=["potted_plant@98%", "potted_plant@98%", "potted_plant@95%"]
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=3, labels=["potted_plant", "potted_plant", "potted_plant"]
[2026-04-20T03:03:35Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=64940
[2026-04-20T03:03:35Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=3, blurredBytes=64940
[2026-04-20T03:03:43Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-20T03:03:43Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=38053, exifOrientation=6
[2026-04-20T03:03:43Z] [DEBUG] [CompanionViewModel.runDetectionPreview:298] runDetectionPreview: start, jpegBytes=38053
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=3, items=["potted_plant@99%", "potted_plant@97%", "table@94%"]
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:282] Stage 3 – object detection (boxes): count=3, items=["potted_plant@99%", "potted_plant@97%", "table@94%"]
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=3, labels=["potted_plant", "potted_plant", "table"]
[2026-04-20T03:03:43Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=48185
[2026-04-20T03:03:43Z] [DEBUG] [CompanionViewModel.runDetectionPreview:328] runDetectionPreview: done, detectionCount=3, blurredBytes=48185
[2026-04-20T03:03:59Z] [DEBUG] [CompanionViewModel.runFullPipeline:339] runFullPipeline: start, mode=cloud, jpegBytes=48185, childAge=6
[2026-04-20T03:03:59Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1014] runCloudPipeline: start, jpegBytes=48185, childAge=6
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 360.0), childAge=6
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 360.0)
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.parseDetections:308] Stage 3 – object detection (recognized): count=2, items=["potted_plant@98%", "potted_plant@96%"]
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:272] Stage 3 – object detection: labels=["potted_plant", "potted_plant"]
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.classifyScene:382] Stage 4 – scene classification: labels=["structure", "wood_processed"]
[2026-04-20T03:03:59Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:399] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-20T03:04:00Z] [DEBUG] [PrivacyPipelineService.process:142] Pipeline benchmark: faceDetect=8ms blur=5ms yolo=53ms scene=53ms stt=53ms piiScrub=0ms total=72ms
[2026-04-20T03:04:00Z] [DEBUG] [PrivacyPipelineService.process:143] Stage 6 – output: objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"], hasTranscript=false
[2026-04-20T03:04:00Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1024] runCloudPipeline: privacy done, objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"], latency=72ms
[2026-04-20T03:04:00Z] [DEBUG] [StoryTimelineStore.insert:42] StoryTimeline: session inserted id=29AFF0E1-6693-40A1-9863-3122336DA91F
[2026-04-20T03:04:00Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=193, keySet=true, objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"]
[2026-04-20T03:04:04Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=390
[2026-04-20T03:04:04Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1043] runCloudPipeline: beat[0] received in 4922ms, beatIndex=0
[2026-04-20T03:04:04Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1044] beat[0] storyText: You gently push open a small wooden door and discover a cozy little house built from smooth, processed wood. The warm sunshine streams in, highlighting two beautiful potted plants sitting by a window. They look so happy and green!
[2026-04-20T03:04:04Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1045] beat[0] question: What do you think these plants might be for?
[2026-04-20T03:04:04Z] [DEBUG] [CompanionViewModel.runCloudPipeline:1046] beat[0] isEnding: false
[2026-04-20T03:04:04Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=228
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:04:19Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=228
[2026-04-20T03:04:19Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=44
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:04:23Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=44
[2026-04-20T03:04:23Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T03:04:23Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T03:04:27Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-20T03:04:28Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-20T03:04:28Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-20T03:04:29Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-20T03:04:30Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-20T03:04:31Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T03:04:31Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T03:04:31Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
Passing along Operation canceled in response to ExecuteRequest
Received ModelManagerError that couldn't be converted to a TokenGenerationError: Operation canceled
[2026-04-20T03:04:32Z] [WARNING] [SemanticTurnDetector.semanticCheck:97] listenForAnswer: Layer 2 error (Failed to deserialize a Generable type from model output), treating as complete
Passing along Request 4572AD5F-4B24-4403-956C-07CAC58EE2F7 not found in response to CancelRequest
[2026-04-20T03:04:32Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T03:04:32Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1670400
[2026-04-20T03:04:32Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=To help breathing inside
[2026-04-20T03:04:32Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='To help breathing inside', length=24
[2026-04-20T03:04:32Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=539, keySet=true, objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"]
[2026-04-20T03:04:37Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=416
[2026-04-20T03:04:37Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='To help breathing inside'
[2026-04-20T03:04:37Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[1] storyText: That's such a wonderful thought, Test Child! You notice how the plants make the air inside feel so fresh and clean, almost like a little breath of the forest right in this cozy room. It makes you feel very comfortable and happy to be here.
[2026-04-20T03:04:37Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[1] question: What do you think you might do in this special little house?
[2026-04-20T03:04:37Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[1] isEnding: false
[2026-04-20T03:04:37Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=237
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:04:52Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=237
[2026-04-20T03:04:52Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=60
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:04:56Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=60
[2026-04-20T03:04:57Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T03:04:57Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T03:05:01Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-20T03:05:01Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-20T03:05:01Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T03:05:03Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T03:05:03Z] [DEBUG] [SemanticTurnDetector.semanticCheck:68] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T03:05:03Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-20T03:05:05Z] [DEBUG] [SemanticTurnDetector.semanticCheck:89] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T03:05:05Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T03:05:05Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T03:05:05Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1516800
[2026-04-20T03:05:05Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-20T03:05:05Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Want to play', length=12
[2026-04-20T03:05:05Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=832, keySet=true, objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"]
[2026-04-20T03:05:10Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=414
[2026-04-20T03:05:10Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Want to play'
[2026-04-20T03:05:10Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[2] storyText: That's a fantastic idea! This cozy little house feels like the perfect place for a gentle adventure. I wonder what fun games you could play here, maybe pretending the plants are magical trees in a miniature forest, or perhaps building a tiny fort.
[2026-04-20T03:05:10Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[2] question: What kind of play do you feel like starting today?
[2026-04-20T03:05:10Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[2] isEnding: false
[2026-04-20T03:05:10Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 3 sentence(s), chars=245
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:05:26Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=3, chars=245
[2026-04-20T03:05:26Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=50
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:05:30Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=50
[2026-04-20T03:05:31Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T03:05:31Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T03:05:37Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-20T03:05:38Z] [DEBUG] [CompanionViewModel.listenForAnswer:607] listenForAnswer: Layer 2 semantic check starting
[2026-04-20T03:05:38Z] [DEBUG] [CompanionViewModel.listenForAnswer:610] listenForAnswer: Layer 2 complete → returning transcript
[2026-04-20T03:05:38Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T03:05:38Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1478400
[2026-04-20T03:05:38Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Yo
[2026-04-20T03:05:38Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='Yo', length=2
[2026-04-20T03:05:38Z] [DEBUG] [CloudAgentService.requestStory:52] requestStory: POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate, bodyBytes=1125, keySet=true, objects=["potted_plant", "potted_plant"], scene=["structure", "wood_processed"]
[2026-04-20T03:05:42Z] [DEBUG] [CloudAgentService.requestStory:65] requestStory: HTTP 200, responseBytes=425
[2026-04-20T03:05:42Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1125] continueCloudLoop: answer='Yo'
[2026-04-20T03:05:42Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1126] beat[3] storyText: You feel a little tingle of excitement knowing there are so many wonderful ways to play in this charming wooden house. Perhaps you could explore every cozy corner, or maybe you want to have a special chat with the happy green plants that make the air feel so fresh.
[2026-04-20T03:05:42Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1127] beat[3] question: What kind of play do you want to start with?
[2026-04-20T03:05:42Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1128] beat[3] isEnding: false
[2026-04-20T03:05:42Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 2 sentence(s), chars=264
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:05:57Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=2, chars=264
[2026-04-20T03:05:57Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 1 sentence(s), chars=44
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:06:01Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=1, chars=44
[2026-04-20T03:06:01Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-20T03:06:01Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-20T03:06:09Z] [DEBUG] [CompanionViewModel.listenForAnswer:564] listenForAnswer: hard cap reached (8s)
[2026-04-20T03:06:09Z] [ERROR] [SpeechRecognitionService.startLiveTranscription:77] recognitionTask error: No speech detected
[2026-04-20T03:06:09Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=1536000
[2026-04-20T03:06:09Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=nil
[2026-04-20T03:06:09Z] [DEBUG] [CompanionViewModel.listenForAnswer:626] listenForAnswer: answer='nil', length=0
[2026-04-20T03:06:09Z] [DEBUG] [CompanionViewModel.continueCloudLoop:1097] continueCloudLoop: answer timeout, ending story
[2026-04-20T03:06:09Z] [DEBUG] [AudioService.speakAll:263] AudioService: speaking 2 sentence(s), chars=126
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-20T03:06:17Z] [DEBUG] [AudioService.speakAll:275] AudioService: speech done, sentences=2, chars=126
[2026-04-20T03:06:17Z] [DEBUG] [StoryTimelineStore.finalizeSession:50] StoryTimeline: session finalised beats=4, restart=false
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b086a00> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14d00c700> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14d00d500> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14d00e300> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14d00f100> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14db00000> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14db00e00> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14db01c00> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentVS_7AnyViewVS_12RootModifier__: 0x14b09c000> (from <_TtGC7SwiftUI32NavigationStackHostingControllerVS_7AnyView_: 0x14d5bed00>) which is already presenting <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x14b087800>.
could not find answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Couldn't get answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Reading from public effective user settings.
Failed to locate container app bundle record. The process may not be entitled to access the LaunchServices database or the app may have moved.
could not find answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Couldn't get answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Failed to locate container app bundle record. The process may not be entitled to access the LaunchServices database or the app may have moved.
could not find answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Couldn't get answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
could not find answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}
Couldn't get answer for domain 8: Error Domain=NSOSStatusErrorDomain Code=-54 "com.apple.private.coreservices.canmaplsdatabase" UserInfo={_LSLine=1104, _LSFunction=-[_LSDReadClient getEligibilityAnswerForDomain:withCompletionHandler:], _LSFile=LSDReadService.mm, NSDebugDescription=com.apple.private.coreservices.canmaplsdatabase}