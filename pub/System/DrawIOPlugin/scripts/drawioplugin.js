(function($) {
  function evthandler(evt) {
    var source = evt.srcElement || evt.target;

    if (source.nodeName == 'IMG' && source.className == 'drawio') {
      if (source.drawIoWindow == null || source.drawIoWindow.closed) {
	// Implements protocol for loading and exporting with embedded XML
	var receive = function(evt) {
	  if (evt.data.length > 0 && evt.source == source.drawIoWindow) {
	    var msg = JSON.parse(evt.data);
	    var srcurl = source.getAttribute('src');
	    var filename = source.getAttribute('filename');
	    // Received if the editor is ready
	    if (msg.event == 'init') {
	      // Fetch image, convert to a data URI and pass to the editor
	      // hard won knowledge from http://stackoverflow.com/questions/20035615/using-raw-image-data-from-ajax-request-for-data-uri
	      // via David Benson <davidjgraph@gmail.com>
	      var xmlHTTP = new XMLHttpRequest();
	      xmlHTTP.open('GET', srcurl, true);
	      xmlHTTP.responseType = 'arraybuffer';
	      xmlHTTP.onload = function(e) {
		var dataURI = "data:image/svg+xml;base64," + data2b64(this.response);

		source.drawIoWindow.postMessage(JSON.stringify({action: 'load', xml: dataURI}), '*');
	      };
	      xmlHTTP.send();
	    }
	    // Received if the user clicks save
	    else if (msg.event == 'save') {
	      // Sends request to export the diagram as SVG with embedded XML
	      source.drawIoWindow.postMessage(JSON.stringify(
		{action: 'export', format: 'xmlsvg', spinKey: 'saving'}), '*');
	    }
	    // Received if the export request was processed
	    else if (msg.event == 'export') {
	      // Construct form to upload file
	      var formData = new FormData();
	      formData.append('noredirect', 1);
	      if (typeof(StrikeOne) !== 'undefined') {
		var key = StrikeOne.calculateNewKey(source.getAttribute('data-validation-key'));
		formData.append('validation_key', key);
	      }
	      var blob = decodeURI(msg.data);
	      formData.append('filepath', blob, filename);

	      var url = foswiki.getScriptUrl(
                'upload',
                foswiki.getPreference('WEB'),
                foswiki.getPreference('TOPIC'));

	      // Actually do the upload
              $.post({
		url : url,
		data: formData,
		mimeType:"multipart/form-data",
                contentType: false, // to protect multipart
                processData: false,
                cache: false
	      }).done(function(data, textStatus, jqXHR) {
		// Upload worked, refresh existing image
		source.setAttribute('src', srcurl + '?' + new Date().getTime());
		// Extract new validation key and update our copy for a subsequent edit
		source.setAttribute('data-validation-key', '?' + jqXHR.getResponseHeader('x-foswiki-validation'));
	      }).fail(function(jqXHR, textStatus, errorThrown) {
		// Upload failed, save the file locally
		savelocalfile(file, filename);
		alert('Saving file locally - failed to upload: ' + jqXHR.responseText);
	      });
	    }

	    // Received if the user clicks exit or after export
	    if (msg.event == 'exit' || msg.event == 'export') {
	      // Closes the editor
	      window.removeEventListener('message', receive);
	      source.drawIoWindow.close();
	      source.drawIoWindow = null;
	    }
	  }
	};
	// Opens the editor
	window.addEventListener('message', receive);
	source.drawIoWindow = window.open(source.getAttribute('drawio-url'));
      } else {
	// Shows existing editor window
	source.drawIoWindow.focus();
      }
    }
  };

  // Encode data as base64
  function data2b64(data) {
    var arr = new Uint8Array(data);
    var raw = String.fromCharCode.apply(null, arr);
    return (btoa(raw));
  }

  // Create blob from data URI
  // https://stackoverflow.com/questions/4998908/convert-data-uri-to-file-then-append-to-formdata
  function decodeURI(data) {
    var byteString;
    if (data.split(',')[0].indexOf('base64') >= 0)
      byteString = atob(data.split(',')[1]);
    else
      byteString = unescape(data.split(',')[1]);

    // separate out the mime component
    var mimeString = data.split(',')[0].split(':')[1].split(';')[0];

    // Create blob to hold data
    var blob = new Blob([byteString], {type: mimeString});

    return blob;
  }

  // Save a blob to a local file
  // https://stackoverflow.com/questions/13405129/javascript-create-and-save-file
  function savelocalfile(blob, filename) {
    if (window.navigator.msSaveOrOpenBlob) // IE10+
      window.navigator.msSaveOrOpenBlob(file, filename);
    else { // Others
      var a = document.createElement("a"),
          url = URL.createObjectURL(blob);
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      setTimeout(function() {
	document.body.removeChild(a);
	window.URL.revokeObjectURL(url);
      }, 0);
    }
  }
  document.addEventListener('dblclick', evthandler);
})(jQuery);
