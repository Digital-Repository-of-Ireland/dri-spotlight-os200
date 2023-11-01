function getAuthzHeader() {
  const headers = new Headers();
  const authToken = Cookies.get('repo_auth');
  if(typeof authToken !== "undefined") {
    headers.set('Authorization', `Basic ${authToken}`);
  }

  return headers;
}

$( document ).on( "ajaxSuccess", function() {
  const authToken = Cookies.get('repo_auth');
      $("img[src^='https://repository.dri.ie/loris']").each(function(){
        displayProtectedImage(this, authToken);
      });
} );

$(document).ready(function (e) {
    $.ajaxSetup({
        global: true,
        beforeSend: function (jqXHR, settings) {
            if(settings.url.startsWith('https://repository.dri.ie') ){
              const authToken = Cookies.get('repo_auth');
              if(typeof authToken !== "undefined") {
                const asciiStringDecoded = atob(authToken);
                const credentials = asciiStringDecoded.split(":");
                settings.url += "?user_email=" + credentials[0] + "&user_token=" + credentials[1];
              }
            }
        }
    });
})

