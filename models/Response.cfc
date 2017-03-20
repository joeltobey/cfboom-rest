component
    displayname="Class Response"
    accessors=true
    output=false
{
    property name="gson" inject="GsonService@cfboomGson";

    property name="type" type="string" validate="regex" validateparams="{pattern=json|jsonp|jsont|gson|wddx|xml|plain|html|text|pdf}";
	property name="data" type="any";
	property name="contentType" type="string";
	property name="encoding" type="string";
	property name="statusCode" type="numeric";
	property name="statusText" type="string";
	property name="location" type="string";
	property name="jsonCallback" type="string";
	property name="jsonQueryFormat" type="string";
	property name="jsonAsText" type="boolean";
	property name="xmlColumnList" type="string";
	property name="xmlUseCDATA" type="boolean";
	property name="xmlListDelimiter" type="string";
	property name="xmlRootName" type="string";
	property name="pdfArgs" type="struct";
	property name="formats" type="string";
	property name="formatsView" type="string";
	property name="binary" type="boolean";

	property name="error" type="boolean";
	property name="messages" type="array";
	property name="errorCode" type="numeric";
	property name="responseTime" type="numeric";
	property name="cachedResponse" type="boolean";
	property name="headers" type="array";

	/**
	 * Add some messages
	 * @message Array or string of message to incorporate
	 */
	function addMessage( required any message ) {
		if ( isSimpleValue( arguments.message ) ) {
			arguments.message = listToArray( arguments.message );
		}
		variables.messages.addAll( arguments.message );
		return this;
	}

	/**
	 * Add a header
	 * @name header name
	 * @value header value
	 */
	function addHeader( required string name, required string value ) {
		arrayAppend( variables.headers, { name=arguments.name, value=arguments.value } );
		return this;
	}

	/**
	 * Returns a standard response formatted data packet
	 */
	function getDataPacket() {
		var returnObject = {};
		if (type == "gson") {
			var gsonObject = gson.object();
			gsonObject.add("error", gson.boolean( getError() ? true : false ));
			gsonObject.add("errorcode", gson.int( getErrorCode() ));
			var messages = gson.array();
			for (var msg in getMessages()) {
				messages.add( gson.string(msg) );
			}
			gsonObject.add("messages", messages);
			if (isInstanceOf(getData(), "com.google.gson.JsonElement")) {
				gsonObject.add("data", getData());
			} else if (isSimpleValue(getData())) {
				gsonObject.add("data", gson.primitive( getData() ));
			} else {
				gsonObject.add("data", gson.parse( serializeJson(getData()) ));
			}
			returnObject = gsonObject.toString();
		} else {
			returnObject = {
				"error" = getError() ? true : false,
				"errorcode" = getErrorCode(),
				"messages" = getMessages(),
				"data" = getData()
			};
		}
		return returnObject;
	}
}