function fetchWithAuthentication(url, authToken) {
  const headers = new Headers();
  headers.set('Authorization', `Basic ${authToken}`);
  return fetch(url, { headers });
}

async function displayProtectedImage(
  image, authToken
) {
  const url = $(image).attr('src');
  // Fetch the image.
  const response = await fetchWithAuthentication(
    url, authToken
  );

  // Create an object URL from the data.
  const blob = await response.blob();
  const objectUrl = URL.createObjectURL(blob);
  
  // Update the source of the image.
  image.src = objectUrl;
  image.onload = () => URL.revokeObjectURL(objectUrl);
}

$(document).on('turbolinks:load', function() { 
  const authToken = Cookies.get('repo_auth');
  $("img[src^='https://repository.dri.ie/loris']").each(function(){
    displayProtectedImage(this, authToken);
  });
});
