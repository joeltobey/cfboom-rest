/**
 * Created by joeltobey on 4/14/17.
 */
component
  displayname="Response Interceptor"
  output="false"
{
  property name="settings" inject="coldbox:modulesettings:cfboom-rest";

  public void function preProcess( event, interceptData, buffer, rc, prc ) {
    initResponse( argumentCollection:arguments );
  }

  public void function renderData( event, targetAction, eventArguments, rc, prc ) {
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

}
