$(document).ready(function() {
  var files = $('#files'), s = $('#status'), editor = $('.editor'), code = $('#big_code'),
  opened_file = null;
  var cm = new CodeMirror(CodeMirror.replace(code[0]), {
    height: '300px',
    content: code.html(),
    parserfile: ["parselua.js"],
    stylesheet: "css/luacolors.css",
    path: "js/",
    autoMatchParens: true,
    lineNumbers: true,
    continuousScanning: true,
    indentUnit: 4,
    tabMode: "shift"
  });
  
  $('#open_file').click(function() {
    var fl = $("#file_list").slideDown();
    $.post('/get_files',{},function(json) {
      files.html('');
      $.each(json, function(i, ele) {
        // for now, only do lua files
        if (ele.match(/\.lua$/)) {
          var li = $('<li class="file">'+ele+'</li>').click(function() {
            var fname = $(this).html();
            $.get('/open_file',{file:fname},function(script) {
              msg('success',"Loaded "+fname);
              fl.slideUp(function() {
                cm.setCode(script);                
              });
              setOpenedFile(fname);
            });
          });
          files.append(li);
        }
      });
    },'json');    
  });
  
  function setOpenedFile(fname) {
    opened_file = fname;
    $('#save_file').removeAttr('disabled');
  }

  function msg(type, msg) {
    s.attr('class',type).html(msg);
  }        

  
  // on submission of inline text, eval code 
  $('#eval_line').submit(function(e) {

    $.ajax({
      type: 'POST',
      url: 'eval',
      data: $(this).serialize(),
      success: function() {
        msg('success',"Success!");
      },
      error: function(xhr, opts) {
        msg('error',xhr.responseText);
      }
    });

    e.preventDefault();
    return false;
  });
  
  $('#save_file').click(function() {
    $.ajax({
      type: 'POST',
      url: 'upload_script',
      data: {file: opened_file, contents: cm.getCode()},
      success: function() { msg('success',"Uploaded "+opened_file); },
      error: function() { msg('error',"Couldn't upload "+opened_file); }
    });
  });
  
  $('#run_file').click(function() {
	$.ajax({
		   type: 'POST',
		   url: 'eval',
		   data: {code: cm.getCode()},
		   success: function() { msg('success',"Ran!"); },
		   error: function() { msg('error',"Couldn't run."); }
		   });
	});
				  
  new AjaxUpload('file_upload', {
    action: '/upload_file',
    name: 'file',
    autoSubmit: true,
    onComplete : function(file){
      msg('success','Uploaded '+file+'!');
    } 
  });

});