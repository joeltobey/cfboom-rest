component
    displayname="Class EventHandlerSupport"
    accessors=true
    output=false
{
    property name="settings" inject="coldbox:modulesettings:cfboom-rest";

    /**
     * Around handler advice
     */
    function aroundHandler( event, targetAction, eventArguments, rc, prc ) {
        try {
            // start a resource timer
            var stime = getTickCount();

            // prepare our response object
            prc['response'] = getModel( "Response@cfboomRest" );
			initResponse( prc.response );

			var contentTypeArray = listToArray( event.getHTTPHeader("Content-Type"), ";" );
			if ( arrayContains(contentTypeArray, "application/json") ) {
				arguments.rc["_content"] = arguments.event.getHTTPContent(true);
			}

            // prepare arguments for action call
            var args = {
                "event" = arguments.event,
                "rc" = arguments.rc,
                "prc" = arguments.prc
            };
            structAppend( args, arguments.eventArguments );

            // execute the action now
            arguments.targetAction( argumentCollection=args );
		} catch (any ex) {

            // Log Locally
            log.error( "Error calling #event.getCurrentEvent()#: #e.message# #e.detail#", e );

            // Setup General Error Response
            prc.response
                .setError( true )
                .setErrorCode( e.errorCode == 0 ? 500 : len( e.errorCode ) ? e.errorCode : 0 )
                .addMessage( "General application error: #e.message#" )
                .setStatusCode( 500 )
                .setStatusText( "General application error" );

            // Development additions
            if ( getSetting( "environment" ) == "development" ){
                prc.response.addMessage( "Detail: #e.detail#" )
                    .addMessage( "StackTrace: #e.stacktrace#" );
			}
		}

		// Development additions
		if ( getSetting( "environment" ) == "development" ){
			prc.response.addHeader( "X-Current-Route", event.getCurrentRoute() )
				.addHeader( "X-Current-Routed-Url", event.getCurrentRoutedURL() )
				.addHeader( "X-Current-Routed-Namespace", event.getCurrentRoutedNamespace() )
				.addHeader( "X-Current-Event", event.getCurrentEvent() );
		}

		// end timer
		prc.response.setResponseTime( getTickCount() - stime );

		// Use event data rendering
		event.renderData(
			type = prc.response.getType() == "gson" ? "plain" : prc.response.getType(),
			data = findNoCase("json", prc.response.getType()) || prc.response.getType() == "gson"
				? prc.response.getDataPacket() : prc.response.getData(),
			contentType = prc.response.getContentType(),
			encoding = prc.response.getEncoding(),
			statusCode = prc.response.getStatusCode(),
			statusText = prc.response.getStatusText(),
			location = prc.response.getLocation(),
			jsonCallback = prc.response.getJsonCallback(),
			jsonQueryFormat = prc.response.getJsonQueryFormat(),
			jsonAsText = prc.response.getJsonAsText(),
			xmlColumnList = prc.response.getXmlColumnList(),
			xmlUseCDATA = prc.response.getXmlUseCDATA(),
			xmlListDelimiter = prc.response.getXmlListDelimiter(),
			xmlRootName = prc.response.getXmlRootName(),
			pdfArgs = prc.response.getPdfArgs(),
			formats = prc.response.getFormats(),
			formatsView = prc.response.getFormatsView(),
			isBinary = prc.response.getBinary()
		);

		// Global Response Headers
		prc.response.addHeader( "X-Response-Time", prc.response.getResponseTime() )
				.addHeader( "X-Cached-Response", prc.response.getCachedResponse() );

		// Response Headers
		for ( var thisHeader in prc.response.getHeaders() ) {
			event.setHTTPHeader( name=thisHeader.name, value=thisHeader.value );
		}
    }

	/**
	 * on localized errors
	 */
	function onError( event, rc, prc, faultAction, exception, eventArguments ){
		// Log Locally
		log.error( "Error in base handler (#arguments.faultAction#): #arguments.exception.message# #arguments.exception.detail#", arguments.exception );
		// Verify response exists, else create one
		if( !structKeyExists( prc, "response" ) ){ prc.response = getModel( "Response@cbrestbasehandler" ); }
		// Setup General Error Response
		prc.response
			.setError( true )
			.setErrorCode( 501 )
			.addMessage( "Base Handler Application Error: #arguments.exception.message#" )
			.setStatusCode( 500 )
			.setStatusText( "General application error" );

		// Development additions
		if( getSetting( "environment" ) eq "development" ){
			prc.response.addMessage( "Detail: #arguments.exception.detail#" )
				.addMessage( "StackTrace: #arguments.exception.stacktrace#" );
		}

		// Render Error Out
		event.renderData(
			type		= prc.response.getType(),
			data 		= prc.response.getDataPacket(),
			contentType = prc.response.getContentType(),
			statusCode 	= prc.response.getStatusCode(),
			statusText 	= prc.response.getStatusText(),
			location 	= prc.response.getLocation(),
			isBinary 	= prc.response.getBinary()
		);
	}

	/**
	 * on invalid http verbs
	 */
	function onInvalidHTTPMethod( event, rc, prc, faultAction, eventArguments ){
		// Log Locally
		log.warn( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#", getHTTPRequestData() );
		// Setup Response
		prc.response = getModel( "Response@cbrestbasehandler" )
			.setError( true )
			.setErrorCode( 405 )
			.addMessage( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#" )
			.setStatusCode( 405 )
			.setStatusText( "Invalid HTTP Method" );
		// Render Error Out
		event.renderData(
			type		= prc.response.getType(),
			data 		= prc.response.getDataPacket(),
			contentType = prc.response.getContentType(),
			statusCode 	= prc.response.getStatusCode(),
			statusText 	= prc.response.getStatusText(),
			location 	= prc.response.getLocation(),
			isBinary 	= prc.response.getBinary()
		);
	}

	private void function initResponse( any response ) {
        arguments.response.setType( settings.defaults.type );
        arguments.response.setData( "" );
        if (settings.defaults.type == "gson") {
        	arguments.response.setContentType( "application/json" );
        } else {
        	arguments.response.setContentType( "" );
        }
        arguments.response.setEncoding( settings.defaults.encoding );
        arguments.response.setStatusCode( 200 );
        arguments.response.setStatusText( "OK" );
        arguments.response.setLocation( "" );
        arguments.response.setJsonCallBack( "" );
        arguments.response.setJsonQueryFormat( settings.defaults.jsonQueryFormat );
        arguments.response.setJsonAsText( false );
        arguments.response.setXmlColumnList( "" );
        arguments.response.setXmlUseCDATA( false );
        arguments.response.setXmlListDelimiter( "," );
        arguments.response.setXmlRootName( "" );
        arguments.response.setPdfArgs( {} );
        arguments.response.setFormats( "" );
        arguments.response.setFormatsView( "" );
        arguments.response.setBinary( false );
        arguments.response.setError( false );
        arguments.response.setMessages( [] );
        arguments.response.setErrorCode( 0 );
        arguments.response.setResponseTime( 0 );
        arguments.response.setCachedResponse( false );
        arguments.response.setHeaders( [] );
	}
}