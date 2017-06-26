/*
 * Copyright 2017 Joel Tobey <joeltobey@gmail.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
  * @author Joel Tobey
  */
component
  displayname="Class EventHandlerSupport"
  output=false
{
  property name="responseInterceptor" inject="ResponseInterceptor@cfboomRest";

  /**
   * Around handler advice
   */
  function aroundHandler( event, targetAction, eventArguments, rc, prc ) {
    try {
      // start a resource timer
      var stime = getTickCount();

      validateRequest( argumentCollection=arguments );

      if (!prc.response.getError()) {
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
      }

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

    responseInterceptor.renderData( argumentCollection:arguments );

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
    responseInterceptor.renderData( argumentCollection:arguments );
  }

  /**
   * on invalid http verbs
   */
  function onInvalidHTTPMethod( event, rc, prc, faultAction, eventArguments ){
    // Log Locally
    log.warn( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#", getHTTPRequestData() );

    // Setup Response
    prc.response
      .setError( true )
      .setErrorCode( 405 )
      .addMessage( "InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#" )
      .setStatusCode( 405 )
      .setStatusText( "Invalid HTTP Method" );

    // Render Error Out
    responseInterceptor.renderData( argumentCollection:arguments );
  }

  private void function validateRequest( event, targetAction, eventArguments, rc, prc ) {
    var messages = [];
    var meta = getMetaData(arguments.targetAction);
    for (var param in meta.parameters) {
      if (structKeyExists(param, "validation-required")) {
        var requiredArray = listToArray( param['validation-required'] );
        if (param.name == "rc") {
          for (var requiredParam in requiredArray) {
            if (!structKeyExists(rc, requiredParam))
              arrayAppend(messages, "Missing required field '#requiredParam#'");
          }
        }
      }
    }

    // Set error if we have messages
    if (arrayLen(messages)) {
      prc.response
        .setError( true )
        .setErrorCode( 400 )
        .setStatusCode( 400 )
        .setStatusText( "Unauthorized" );

      for (var msg in messages) {
        prc.response.addMessage( msg );
      }
    }
  }

}
