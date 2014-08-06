#!/usr/bin/awk -f

#### twilio-forward_sms.cgi
##
## Little "twimlet" to forward SMS messages to another phone number.
## 
## License: GPL v3
##
## Notes:
## * You might need to modify the path on the first line of this file to
##   find your installed version of 'awk'. It might be called 'mawk' or
##   'gawk'.
## * Update the 'recipient_phone_number" variable to the phone number
##   that you want to forward SMS to.
## * Adapted from:
##   https://www.twilio.com/help/faq/sms/how-do-i-forward-my-sms-messages-to-another-phone-number

### percentDecode
## Turn percent-encoded message into plain text:

function percentDecode(percentEncodedString) {

    ## Use the information here
    ## https://en.wikipedia.org/wiki/Percent-encoding
    ## to create an associative array, and iterate over it,
    ## performing global search and replaces (gsub)

    split(percentEncoding,coding_pairs,/a/)

    for ( pair in coding_pairs ) {

	    split(coding_pairs[pair],value_attribute,/b/)
    
	    gsub(value_attribute[2],value_attribute[1],percentEncodedString)

	}

    return percentEncodedString

}


### Function: queryString2array
##
## Description:
##
## This function takes the raw webserver-provided QUERY_STRING
## environment variable and loads the content of attribute values into
## the 'decoded_parameters' array.
##
## Input:
## * queryString
##   The raw QUERY_STRING from GET or POST method.
##
## Output: None
##
## Side-effects: 
## Loads content into the global 'attributes' array.


function queryString2array (queryString, decoded_parameters,          parameters, attribute_value) {

    split(queryString,parameters,/&/)

    ## Dump message parts to text files:

    for ( parameter in parameters ) {
	
	split(parameters[parameter],attribute_value,/=/)

	decoded_parameters[attribute_value[1]] = percentDecode(attribute_value[2])

    }

}

### escapeHtmlSpecialChars
## 
## Utility function to sanitize user input before constructing XML to
## send to Twilio. 

function escapeHtmlSpecialChars (string) {

    gsub(/&/,"&amp;",string)
    gsub(/"/,"&quot;",string)
    gsub(/'/,"&apos;",string)
    gsub(/</,"&lt;",string)
    gsub(/>/,"&gt;",string)

    return string
    
}

BEGIN {

    ## Create web page:
    print "Content-type: text/html\n\n"
    
    ## This information was scraped from:
    ## https://en.wikipedia.org/wiki/Percent-encoding
    ## Non-encoded characters 'a' and 'b' are used to delimit pairs, 
    ## and unencoded characters and their encoded representation, respectively:
    percentEncoding = "!b%21a#b%23a$b%24a&b%26a'b%27a(b%28a)b%29a*b%2Aa+b%2Ba,b%2Ca/b%2Fa:b%3Aa;b%3Ba=b%3Da?b%3Fa@b%40a[b%5Ba]b%5Da b%20a b+a\\\"b%22a%b%25a-b%2Da.b%2Ea<b%3Ca>b%3Ea\\b%5Ca^b%5Ea_b%5Fa`b%60a{b%7Ba|b%7Ca}b%7Da~b%7Ea\nb%0D%0Aa\nb%0Aa\nb%0D"
    
    recipient_phone_number="+XXXXXXXXXXXX"

}

{ postQueryString = $0 }

END {

    ## Instantiate request_vars global array:
    split("",request_vars)
    ## Parse encoded parameter string into variables:
    queryString2array(postQueryString,request_vars)

    ## Construct the XML chunk for Twilio:
    print "<Response>"
    print "   <Message to=\"" recipient_phone_number "\">"
    print escapeHtmlSpecialChars( substr("Original SMS from " request_vars["From"] ": " request_vars["Body"] , 0, 160 ) ) 
    print "   </Message>"
    print "</Response>"

}
