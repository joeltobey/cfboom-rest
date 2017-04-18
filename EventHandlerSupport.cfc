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

      initResponse( argumentCollection:arguments );

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
      log.error( "Error calling #event.getCurrentEvent()#: #ex.message# #ex.detail#", ex );

      // Setup General Error Response
      prc.response
        .setError( true )
        .setErrorCode( ex.errorCode == 0 ? 500 : len( ex.errorCode ) ? ex.errorCode : 0 )
        .addMessage( "General application error: #ex.message#" )
        .setStatusCode( 500 )
        .setStatusText( "General application error" );

      // Development additions
      if ( getSetting( "environment" ) == "development" ){
        prc.response.addMessage( "Detail: #ex.detail#" )
                    .addMessage( "StackTrace: #ex.stacktrace#" );
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

    renderData( argumentCollection:arguments );

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

    initResponse( argumentCollection:arguments );

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
    renderData( argumentCollection:arguments );
  }

  /**
   * on invalid http verbs
   */
  function onInvalidHTTPMethod( event, rc, prc, faultAction, eventArguments ){
    // Log Locally
    log.warn( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#", getHTTPRequestData() );

    initResponse( argumentCollection:arguments );

    // Setup Response
    prc.response
      .setError( true )
      .setErrorCode( 405 )
      .addMessage( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#" )
      .setStatusCode( 405 )
      .setStatusText( "Invalid HTTP Method" );

    // Render Error Out
    renderData( argumentCollection:arguments );
  }

  private void function initResponse( event, targetAction, eventArguments, rc, prc ) {
    if ( !structKeyExists( prc, "response" ) ) {
      prc['response'] = getModel( "Response@cfboomRest" );
      prc.response.setType( settings.defaults.type );
      prc.response.setData( "" );
      if (settings.defaults.type == "gson") {
        prc.response.setContentType( "application/json" );
      } else {
        prc.response.setContentType( "" );
      }
      prc.response.setEncoding( settings.defaults.encoding );
      prc.response.setStatusCode( 200 );
      prc.response.setStatusText( "OK" );
      prc.response.setLocation( "" );
      prc.response.setJsonCallBack( "" );
      prc.response.setJsonQueryFormat( settings.defaults.jsonQueryFormat );
      prc.response.setJsonAsText( false );
      prc.response.setXmlColumnList( "" );
      prc.response.setXmlUseCDATA( false );
      prc.response.setXmlListDelimiter( "," );
      prc.response.setXmlRootName( "" );
      prc.response.setPdfArgs( {} );
      prc.response.setFormats( "" );
      prc.response.setFormatsView( "" );
      prc.response.setBinary( false );
      prc.response.setError( false );
      prc.response.setMessages( [] );
      prc.response.setErrorCode( 0 );
      prc.response.setResponseTime( 0 );
      prc.response.setCachedResponse( false );
      prc.response.setHeaders( [] );
      prc.response.setUseEnvelope( settings.defaults.useEnvelope );
    }
  }

  private void function renderData( event, targetAction, eventArguments, rc, prc ) {
    // Use event data rendering
    event.renderData(
      type = prc.response.getType() == "gson" ? "plain" : prc.response.getType(),
      data = listFindNoCase("json,gson", prc.response.getType()) ? prc.response.getDataPacket() : prc.response.getData(),
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
  }
}
