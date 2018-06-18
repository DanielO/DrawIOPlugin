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
	      var data = source.getAttribute('src');
	      source.drawIoWindow.postMessage(JSON.stringify({action: 'load', xml: data}), '*');
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
		alert('upload done');
		// XXX: new nonce is null..
		//console.log('new nonce ' + jqXHR.getResponseHeader('X-Foswiki-Validation'));
	      }).fail(function(jqXHR, textStatus, errorThrown) {
		alert('failed to upload');
	      });
	      // Updates the data URI of the image
	      source.setAttribute('src', msg.data);
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
