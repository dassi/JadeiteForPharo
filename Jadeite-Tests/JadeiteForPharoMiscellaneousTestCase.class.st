Class {
	#name : 'JadeiteForPharoMiscellaneousTestCase',
	#superclass : 'JadeiteForPharoGUITestCase',
	#category : 'Jadeite-Tests',
	#package : 'Jadeite-Tests'
}

{ #category : 'support' }
JadeiteForPharoMiscellaneousTestCase >> focusWidgetText [

	^ UIManager default world activeHand keyboardFocus model model text
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_adHocCompileError [
	"When the popup is raised in the workspace, the focus widget should be the popover.
	We try to get that based on which widget is active as the workspace has no memory of the popover"

	self
		testsIssue: #issue688
		withTitle: '(3.0.92) Compile Errors in Workspace broken'.
	workspace := JadeiteWorkspace showOnSession: session.
	workspace setDocumentData: '#(1 2'.
	workspace codePane documentPresenter setFocus.
	workspace codePane jadeExecute.
	self
		assert: self focusWidgetText asString
		equals: '#(1 2 expected a right parenthesis'
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_adHocDisplay [

	self
		testsIssue: #issue427
		withTitle: '(3.0.60) autocommit not done after successful doits'.
	workspace := JadeiteWorkspace showOnSession: session.
	self assert: (workspace isKindOf: JadeiteWorkspace).
	workspace text: '123'.
	workspace codePane documentPresenter setFocus.
	self displayAndPrint.
	self
		assert: workspace codePane documentPresenter text asString
		equals: '123 "123"'
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_adHocExecute [

	self
		testsIssue: #issue427
		withTitle: '(3.0.60) autocommit not done after successful doits'.
	workspace := JadeiteWorkspace showOnSession: session.
	self assert: (workspace isKindOf: JadeiteWorkspace).
	session executeString: 'UserGlobals removeKey: #foo ifAbsent:[]'.
	workspace setDocumentData: 'UserGlobals at: #foo put: ''bar'''.
	workspace codePane documentPresenter setFocus.
	workspace codePane jadeExecute.
	self
		assert: workspace codePane documentPresenter text
		equals: 'UserGlobals at: #foo put: ''bar'''.
	self
		assert: (session executeString: 'UserGlobals at: #foo')
		equals: 'bar'
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_adHocInspect [
	| inspector | 
	self
		testsIssue: #issue427
		withTitle: '(3.0.60) autocommit not done after successful doits'.
	workspace := JadeiteWorkspace showOnSession: session.
	self assert: (workspace isKindOf: JadeiteWorkspace).
	workspace text: '123'.
	workspace codePane documentPresenter setFocus.
	inspector := workspace codePane  
evaluateInspectingResult: workspace codePane text onCompileError: [  ] onError: [  ]. 	
	self assert: inspector selectedInstVar equals: 'self'. 
	self assert: inspector _documentPresenter text equals: '123'.
	self destroy: inspector. 
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_cancel [
	"make sure text reverts after cancel"

	| path |
	path := '$HOME/jfp_testfile_deleteme'.
	workspace := JadeiteWorkspace showOnSession: session.
	workspace setDocumentData: '#(1 2 3)'.
	workspace filePathString: path.
	workspace saveServerFile.
	[
	self deny: workspace adapter widget hasUnacceptedEdits.
	workspace codePane text: '#(1 2 3)  add some text'.
	self assert: workspace adapter widget hasUnacceptedEdits.
	self
		assert: workspace codePane text
		equals: '#(1 2 3)  add some text'.
	workspace triggerResetAction.
	self deny: workspace adapter widget hasUnacceptedEdits.
	self assert: workspace codePane text equals: '#(1 2 3)' ] ensure: [
		| fileService |
		fileService := RowanFileServiceClient new
			               path: path;
			               session: GciSession current;
			               yourself.
		fileService remove ]
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_classServiceNameIsString [
	| classService |
	self testsIssue: #issue441
		withTitle: '(3.0.62) suspicious code in RowanClassService>>hierarchyClassServiceFor:'.
	classService := RowanClassService named: 'RowanClassServiceTest'.
	self assert: classService name isKindOf: String.
	classService := RowanClassService new name: 'RowanClassServiceTest'.
	self assert: classService name isKindOf: String
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_gitVersionDisplay [

	| connectionLauncher jfpSha gemstoneFFISha rsrSha clientServicesSha browserService desiredWorkspaceText |
	self
		testsIssue: #issue29
		withTitle:
		'Need a report to show what all git repository shas I have loaded'.
	connectionLauncher := JadeiteConnectionLauncher allInstances first.
	self deny: connectionLauncher connectionProfile connection isNil. "assume connected"
	workspace := connectionLauncher openCommitIdWindow.
	[
	jfpSha := (IceRepository registry detect: [ :ea |
		           ea name = 'JadeiteForPharo' ]) properties commitish
		          shortId.
	gemstoneFFISha := (IceRepository registry detect: [ :ea |
		                   ea name = 'PharoGemStoneFFI' ]) properties
		                  commitish shortId.
	rsrSha := (IceRepository registry detect: [ :ea |
		           ea name = 'RemoteServiceReplication' ]) properties
		          commitish shortId.
	browserService := RowanBrowserService new.
	browserService command: #updateProjects.
	browserService command: #updateProjects.
	RowanServiceUpdater current
		issueCommand: browserService
		session: (GciSession new library:
				 connectionLauncher connectionProfile connection)
		onCompletion: [  ].
	clientServicesSha := (browserService projects detect: [
		                      :projectService |
		                      projectService name = 'RowanClientServices' ])
		                     sha.
	desiredWorkspaceText := 'Client:*
JadeiteForPharo ' , jfpSha asString , '
PharoGemStoneFFI ' , gemstoneFFISha asString , '
RemoteServiceReplication ' , rsrSha asString , '
---------------------------------------------
Server:*RowanClientServices ' , clientServicesSha asString, '*'.
	self assert: (desiredWorkspaceText match: workspace text asString ) ]
		ensure: [ self destroy: workspace ]
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_methodServiceClassNameIsString [
	| methodService |
	self testsIssue: #issue441
		withTitle: '(3.0.62) suspicious code in RowanClassService>>hierarchyClassServiceFor:'.
	methodService := RowanMethodService new
				selector: 'fnoodle';
				className: 'JadeiteMiscellaneousTestCase';
				meta: false.
	self assert: methodService className isKindOf: String.
	methodService := RowanMethodService new
				selector: 'fnoodle';
				className: #JadeiteForPharoMiscellaneousTestCase;
				meta: false.
	self assert: methodService className isKindOf: String
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_returnedServices [
	"sanity test that we can use the returned services in other tests"

	workspace := JadeiteWorkspace showOnSession: session.
	self assert: (workspace isKindOf: JadeiteWorkspace).
	workspace text: '123'.
	workspace codePane documentPresenter setFocus.
	self displayAndPrint.
	self
		assert: workspace codePane documentPresenter text asString
		equals: '123 "123"'.
	self assert: RowanServiceUpdater current updates size equals: 1.
	self assert: (RowanServiceUpdater current updates first isKindOf:
			 RowanAnsweringService).
	self
		assert: RowanServiceUpdater current updates first answer last
		equals: '123'
]

{ #category : 'tests' }
JadeiteForPharoMiscellaneousTestCase >> test_serviceClassBookkeeping [
	"All service classes should have an entry in`Rowan platform serviceClasses`. 
	Only SystemUser can reference rowan services classes directly so other users
	must use indirection to look up the class. Hence the necessity of this extra
	bookkeeping"

	| testService remoteClassNameSymbols |
	self todo: ["symbols used for autocomplete which isn't implemented yet"
	self testsIssue: #issue687 withTitle: 'inspection as DataCurator broken'.
	"check all client service classes exist on server"
	RowanService subclasses do: 
			[:subclass |
			| remoteClassExists clientClassName |
			clientClassName := subclass name.
			remoteClassExists := session
						executeString: '| serviceClass | 
								serviceClass := Rowan platform serviceClasses detect:[:ea | ea name = '
								, clientClassName printString , '] ifNone:[].
								serviceClass notNil'.
			self assert: remoteClassExists].

	"check all remote service classes exist on client"
	remoteClassNameSymbols := session executeString: '(RowanService subclasses collect:[:cls | cls name]) asArray'.
	remoteClassNameSymbols do:[:className |
		self denyIsNil: (Smalltalk at: className ifAbsent: [  ])]]

]

{ #category : 'as yet unclassified' }
JadeiteForPharoMiscellaneousTestCase >> test_workspaceBrowseProjects [

	self
		testsIssue: #issue265
		withTitle: 'workspace could use a `browse projects` menu item ... '.
	workspace := JadeiteWorkspace showOnSession: session.

	projectsBrowser := workspace openBrowser.
	self assert: projectsBrowser isKindOf: JadeiteBrowser
]

{ #category : 'support' }
JadeiteForPharoMiscellaneousTestCase >> writeUnicodeFile [
	"write out a text file with unicode characters"

	| service |
	service := RowanFileServiceClient new.
	service
		command: #writeFileWithUnicode;
		commandArgs: Array new.
	service issueCommand: service session: session
]
