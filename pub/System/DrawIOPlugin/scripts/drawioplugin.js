$(function() {
  document.addEventListener('dblclick', function(evt) {
    var url = 'https://www.draw.io/?embed=1&ui=atlas&spin=1&modified=unsavedChanges&proto=json';
    var source = evt.srcElement || evt.target;

    if (source.nodeName == 'IMG' && source.className == 'drawio') {
      if (source.drawIoWindow == null || source.drawIoWindow.closed) {
	// Implements protocol for loading and exporting with embedded XML
	var receive = function(evt) {
	  if (evt.data.length > 0 && evt.source == source.drawIoWindow) {
	    var msg = JSON.parse(evt.data);

	    // Received if the editor is ready
	    if (msg.event == 'init') {
	      // Sends the data URI with embedded XML to editor
	      var dataurl = source.getAttribute('src');
	      // hard won knowledge from http://stackoverflow.com/questions/20035615/using-raw-image-data-from-ajax-request-for-data-uri
	      // via David Benson <davidjgraph@gmail.com>
	      var xmlHTTP = new XMLHttpRequest();
	      xmlHTTP.open('GET', dataurl, true);
	      xmlHTTP.responseType = 'arraybuffer';
	      xmlHTTP.onload = function(e) {
		var arr = new Uint8Array(this.response);
		var raw = String.fromCharCode.apply(null, arr);
		var b64 = btoa(raw);
		var dataURI = "data:image/svg+xml;base64," + b64;
		source.drawIoWindow.postMessage(JSON.stringify({action: 'load', xml: dataURI}), '*');
	      };
	      xmlHTTP.send();
	    }
	    // Received if the user clicks save
	    else if (msg.event == 'save') {
	      console.log('saving');
	      // Sends a request to export the diagram as XML with embedded SVG
	      source.drawIoWindow.postMessage(JSON.stringify(
		{action: 'export', format: 'xmlsvg', spinKey: 'saving'}), '*');
	    }
	    // Received if the export request was processed
	    else if (msg.event == 'export') {
	      console.log('exporting');
	      var params = {
		filename : source.getAttribute('filename'),
		_web : foswiki.getPreference('WEB'),
		_topic : foswiki.getPreference('TOPIC'),
		data : msg.data,
	      };
	      if (typeof(StrikeOne) !== 'undefined') {
		var key = source.getAttribute('data-validation-key');
		var key1 = StrikeOne.calculateNewKey(key);
		console.log('Transformed ' + key + ' to ' + key1);
		params['data-validation-key'] = key1;
	      }
	      $.post(foswiki.getScriptUrl('rest', 'DrawIOPlugin', 'upload'), params).done(function(data, textStatus, jqXHR) {
		// Force existing image to be reloaded
		source.setAttribute('src', source.getAttribute('src') + '?' + new Date().getTime());
	      }).fail(function(jqXHR, textStatus, errorThrown) {
		// Failed to upload, get the browser to save the file to rescue user effort.
		// https://stackoverflow.com/questions/13405129/javascript-create-and-save-file
		// https://stackoverflow.com/questions/4998908/convert-data-uri-to-file-then-append-to-formdata
		var byteString;
		if (msg.data.split(',')[0].indexOf('base64') >= 0)
		  byteString = atob(msg.data.split(',')[1]);
		else
		  byteString = unescape(msg.data.split(',')[1]);

		// separate out the mime component
		var mimeString = msg.data.split(',')[0].split(':')[1].split(';')[0];

		var file = new Blob([byteString], {type: mimeString});
		if (window.navigator.msSaveOrOpenBlob) // IE10+
		  window.navigator.msSaveOrOpenBlob(file, source.getAttribute('filename'));
		else { // Others
		  var a = document.createElement("a"),
                      url = URL.createObjectURL(file);
		  a.href = url;
		  a.download = source.getAttribute('filename');
		  document.body.appendChild(a);
		  a.click();
		  setTimeout(function() {
		    document.body.removeChild(a);
		    window.URL.revokeObjectURL(url);
		  }, 0);
		}

		alert('Saving file locally - failed to upload: ' + jqXHR.responseText);
	      });
	    }

	    // Received if the user clicks exit or after export
	    if (msg.event == 'exit' || msg.event == 'export') {
	      console.log('exiting');
	      // Closes the editor
	      window.removeEventListener('message', receive);
	      source.drawIoWindow.close();
	      source.drawIoWindow = null;
	    }
	  }
	};
	// Opens the editor
	window.addEventListener('message', receive);
	source.drawIoWindow = window.open(url);
      }
      else
      {
	// Shows existing editor window
	source.drawIoWindow.focus();
      }
    }
  });
});
