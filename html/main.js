function ucwords(str) {
    return (str + '').replace(/^(.)|\s(.)/g, function ($1) {
        return $1.toUpperCase();
    });
}

$(document).ready(function() {
  var files = $('#files'), 
      gallery_files = $('#gallery_files'),
      s = $('#status'), 
      editor = $('.editor'), 
      code = $('#big_code'),
      player = $("#jquery_jplayer"),
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
    files.html('<h3>Files on device:</h3>');
    
    $(['root','doc']).each(function(i, dirtype) {
      $.post('/get_files',{dirtype: dirtype},function(json) {
        files.append('<p class="header">'+ucwords(dirtype)+':</p>');
        $.each(json, function(i, ele) {
          // for now, only do lua files
          if (ele.match(/\.lua$/)) {
            var li = $('<li class="file">'+ele+'</li>').click(function() {
              var fname = $(this).html();
              $.get('/open_file',{file:fname, dirtype:dirtype},function(script) {
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
  });

  player.jPlayer({
    nativeSupport: true, 
    oggSupport: false, 
    customCssIds: true,
    swfPath: 'js/jplayer'
  })
  .jPlayer("onSoundComplete", function() {
    this.element.jPlayer("play");
  });
  
  function playSnd(url) {
    stopSnd();
    player.jPlayer('setFile',url).jPlayer('play');
  }
  function stopSnd() {
    player.jPlayer('stop');
  }
  
  $('#open_gallery').click(function() {
    var gl = $('#gallery_list').slideDown();
    gallery_files.html('<h3>Resources on device:</h3>');

    // don't try to do doc at this point b/c although we can do directory
    // listing on it, it's a PIA to actual let the browser download them.
    $(['root']).each(function(i, dirtype) {
      $.post('/get_files',{dirtype: dirtype},function(json) {
        gallery_files.append('<p class="header">'+ucwords(dirtype)+':</p>');
        $.each(json, function(i, ele) {
          var path = '/'+ele, 
              m_img = "bmp|png|gif|jpg|jpeg",
              m_snd = "mp3|wav",
              li = $('<li class="resource">'+ele+'</li>');
          if (ele.match('\.('+m_img+')$')) {
            li.qtip({content:'<img src="'+path+'"/>'});
            gallery_files.append(li);
          }
          else if (ele.match('\.('+m_snd+')$')) {
            li.bind({
              mouseover: function() { playSnd(path); },
              mouseout: function() { stopSnd(); },
              click: function() { window.location = path; }
            });
            gallery_files.append(li);
          }
          
        });
      },'json');          
    });
    
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
      url: '/eval',
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
      url: '/upload_script',
      data: {file: opened_file, contents: cm.getCode()},
      success: function() { msg('success',"Uploaded "+opened_file); },
      error: function() { msg('error',"Couldn't upload "+opened_file); }
    });
  });
  
  $('#run_file').click(function() {
    $.ajax({
      type: 'POST',
      url: '/eval',
      data: {code: cm.getCode()},
      success: function() { msg('success',"Ran "+opened_file); },
      error: function(xhr, opts) { msg('error',xhr.responseText); }
    });
  });
  
  $('#reindent').click(function() {
    cm.reindent();
  });
  
  $('#extend_box').click(function() {
    var box=$(".CodeMirror-wrapping")
    box[0].style.height=(parseInt(box[0].style.height)+100)+"px";
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