function fetchWithAuthentication(url) {
  const headers = getAuthzHeader();
  return fetch(url, { headers });
}

async function displayProtectedImage(image) {
  const url = $(image).attr('src');
  // Fetch the image.
  const response = await fetchWithAuthentication(url);

  // Create an object URL from the data.
  const blob = await response.blob();
  const objectUrl = URL.createObjectURL(blob);
  
  // Update the source of the image.
  image.src = objectUrl;
  image.onload = () => URL.revokeObjectURL(objectUrl);
}

$(document).on('turbolinks:load', function() { 
  $("img[src^='https://repository.dri.ie/loris']").each(function(){
    displayProtectedImage(this);
  });
});

