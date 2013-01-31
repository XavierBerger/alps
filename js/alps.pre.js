$(function () {

  $(".dialog-confirm").hide();

  var tab_counter = [% $id %];
  var senderId = -1;

  // ------------------------------------------------------------------
  // TAB
  // ------------------------------------------------------------------
  // add addtab dialog management
  var $addtab_title_input = $("#addtab_title");
  var $edittab_title_input = $("#edittab_title");

  //Add tab and the default button
  var $tabs = $("#tabs").tabs({
      tabTemplate : "<li><a href='#{href}'>#{label}</a>",
      add : function (event, ui) {
        $(ui.panel).append(" [% $page->AddTab("\"+tab_counter+\"") %] ");
      },
      cookie : {
        expires : 365
      }
    });

  // Add "+" at the end of tabs to add new tab
  function addPlus() {
    $("#tabs-ul")
    .append('<li class="ui-add-tab"><a id="add_tab">+</a></li>')
    .live("click", function () {
      $addtab.dialog("open")
    });
  }

  addPlus();

  // Sortable tab
  $tabs.find(".ui-tabs-nav").sortable({
    stop : function (event, ui) {
      var csv = "";
      $("#tabs > ul > li > a").each(function (i) {
        if (this.href != "") {
          csv += (csv == "" ? "" : ",") + this.href.split("-")[1];
        }
      });
      $.post("MoveTab", {
        order : csv
      },
        function (data) {
        return
      }, "json")
      .fail(
        function (data) {
        alert("Error code: " + data.status + "\n"
           + data.statusText + "\n"
           + data.responseText);
      });
    }
  });

  // Add new tab by sending a post to server
  function addtab() {
    var addtab_title = $addtab_title_input.val() || "tab_title";
    $.post("AddTab", {
      title : addtab_title
    }, function (data) {
      $(".ui-add-tab").remove();
      $tabs.tabs("add", "#tabs-" + data.idsys, addtab_title);
      $tabs.tabs("select", "#tabs-" + data.idsys);
      $tabs.tabs("active", "#tabs-" + data.idsys);
      addPlus();
      tab_counter++;
    })
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }
  [% $this->AddDialog('addtab'); %]

  function deletetab() {
    var selected = $('.ui-tabs-selected a').attr('href').split('-')[1];
    $.post("DeleteTab", {
      tabid : selected
    }, function (data) {
      $tabs.tabs("remove", selected);
    })
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }

  //deletetab dialog
  [% $this->DeleteDialog('deletetab') %]


  // edittab button
  $(".edittab").live("click", function () {
    senderId = $(this).attr('id').substr(8, 100);
    var selected = $tabs.tabs('option', 'selected');
    $edittab_title_input.val($("#tabs-ul>li").eq(selected).text());
    $edittab.dialog("open");
  });

  // edittab function
  function edittab() {
    $.post("EditTab", {
      idsys : senderId,
      newtitle : $edittab_title_input.val()
    }, function (data) {
      var selected = $tabs.tabs('option', 'selected');
      $("#tabs-ul>li:eq(" + selected + ") a").text(data.newtitle);
    }, "json")
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }

  // edittab dialog
  [% $this->EditDialog('edittab') %]

  // ---------------------------------------------------------
  // COMPONENT
  // ---------------------------------------------------------
  // componentlist
  $(".componentlist").sortable({
    stop : function (event, ui) {
      $.post("MoveComponent", {
        order : $(this).sortable("serialize")
      },
        function (data) {
        return
      }, "json")
      .fail(
        function (data) {
        alert("Error code: " + data.status + "\n"
           + data.statusText + "\n"
           + data.responseText);
      });
    }
  });
  $(".componentlist").disableSelection();

  // addcomponent button
  $(".addcomponent").live("click", function () {
    $addcomponent.dialog("open");
  });

  // addcomponent function
  function addcomponent() {
    var selected = $tabs.tabs('option', 'selected');
    $.post("AddComponent", {
      tabid : selected,
      name : $("input#component_name").val() || "Component",
      comment : $("textarea#component_comment").val() || "Comment"
    },
      function (data) {
      $("#componentlist-" + data.idtab)
      .append(" [% $this->{'alps'}->{'page'}->AddComponent( '" + data.idsys + "','" + data.name + "','" + data.comment + "') %] ");
    }, "json")
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }

  // addcomponent dialog
  [% $this->AddDialog('addcomponent') %]

  // deletecomponent button
  $(".deletecomponent").live("click", function () {
    senderId = $(this).attr('id').substr(16, 100);
    $deletecomponent.dialog("open");
  });

  // deletecomponent function
  function deletecomponent() {
    $.post("DeleteComponent", {
      idsys : senderId
    }, function (data) {
      $("#componentPanel-" + senderId).remove();
    })
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }

  // deletecomponent dialog
  [% $this->DeleteDialog('deletecomponent') %]

  // editcomponent button
  $(".editcomponent").live("click", function () {
    componentId = $(this).attr('id').substr(14, 100);
    $("#editcomponent_name").val($("#componenttitle-" + componentId + " b").text())

    var content = "";
    $(".shortcutList").empty();
    $("#shortcutList-" + componentId + " li").each(function (i) {
      var idshortcut = $(this).attr('idsys');
      content = content + "<li idsys='"+idshortcut+"' id='shortcut-"+idshortcut+"' class='ui-state-default'>"+
                            "<span class='ui-icon ui-icon-arrowthick-2-n-s move'></span>"+
                            "<span id='name-"+ idshortcut +"' class='text'>" + $(this).children('a').text() + "</span>"+
                            "<input type='hidden' id='link-"+ idshortcut +"' value='" + $(this).children('a').attr('href') + "'>"+
                            "<div id='editshortcut-"+idshortcut+"' class='ui-icon ui-icon-pencil edit editshortcut' role='button'></div>"+
                            "<div id='deleteshortcut-"+idshortcut+"' class='ui-icon ui-icon-close close deleteshortcut' role='button'></div>"+
                          "</li>"
    });
    $('.shortcutList').append(content);

    $editcomponent.dialog("open");
  });

  // editcomponent function
  function editcomponent() {
    $.post("MoveShortcut", {
       order : $(".shortcutList").sortable("serialize")
      },
        function (data) {
          var content="";
          $("#shortcutList-" + componentId).empty();
          $("#shortcutList li").each(function (i) {
            var idshortcut = $(this).attr('idsys');
            var link = $("#link-" + idshortcut).val();
            var name = $("#name-" + idshortcut).html();
            content = content + "<li idsys='"+ idshortcut +"' id='shortcut-"+idshortcut+"'class='sortable'><a href='"+ link +"'>"+ name +"</a></li>";
          });
          $("#shortcutList-" + componentId).append(content);
      }, "json")
      .fail(
        function (data) {
        alert("Error code: " + data.status + "\n"
           + data.statusText + "\n"
           + data.responseText);
      });

    $.post("EditComponent", {
      idsys : componentId,
      newname : $("#editcomponent_name").val()
      },
      function (data) {
      $("#componenttitle-" + componentId + " b").text(data.newname)
      },
      "json")
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
      });
  }

  // editcomponent dialog
  [% $this->EditDialog('editcomponent') %]

  // ---------------------------------------------------------
  // SHORTCUTS
  // ---------------------------------------------------------
  // add addshortcut dialog management
  [% $this->AddDialog('addshortcut') %]

  // Add addshortcut button
  $(".addshortcut").live("click", function () {
    componentIdsys = $(this).attr('id').substr(12, 100);
    $addshortcut.dialog("open");
  });

  // Add new tab by sending a post to server
  function addshortcut() {
    $.post("AddShortcut", {
      idcomponent : componentIdsys,
      name : $("#shortcut_name").val(),
      command : $("#shortcut_command").val()
    },
      function (data) {
      $("#shortcutList-" + data.idcomponent)
      .append(" [% $this->{'alps'}->{'page'}->AddShortcut( '" + data.idsys + "','" + data.name + "','" + data.command + "') %] ");
    },
      "json")
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }

  $(".shortcutList").sortable();

  // editshortcut dialog
  [% $this->EditDialog('editshortcut') %]

  // editshortcut button
  $(".editshortcut").live("click", function () {
    shortcutId = $(this).parent().attr('idsys');
    $("#editshortcut_name").val($("#name-" + shortcutId).html());
    $("#editshortcut_command").val($("#link-" + shortcutId).val());
    $editshortcut.dialog("open");
  });

  // edittab function
  function editshortcut() {
    $.post("EditShortcut", {
      shortcutId : shortcutId,
      newname : $('#editshortcut_name').val(),
      newcommand: $('#editshortcut_command').val()
    }, function (data) {
      $("#link-" + shortcutId).val(data.command);
      $("#name-" + shortcutId).html(data.name);
    }, "json")
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }


  [% $this->DeleteDialog('deleteshortcut') %]

  // deleteshortcut button
  $(".deleteshortcut").live("click", function () {
    shortcutId = $(this).parent().attr('idsys');
    $deleteshortcut.dialog("open");
  });

  // deleteshortcut function
  function deleteshortcut() {
    $.post("DeleteShortcut", {
      shortcutId : shortcutId
    }, function (data) {
      $("#shortcut-" + shortcutId).remove();
    })
    .fail(
      function (data) {
      alert("Error code: " + data.status + "\n"
         + data.statusText + "\n"
         + data.responseText);
    });
  }


  // ---------------------------------------------------------
  // HELP
  // ---------------------------------------------------------
  var $help = $("#help").dialog({
      width : 900,
      autoOpen : false,
      modal : true,
      buttons : {
        Close : function () {
          $(this).dialog("close");
        }
      },
      close : function () {
        $form[0].reset();
      }
    });

  $("#helplink")
  .click(function () {
    $help.dialog("open");
  });

  //if ( tab_counter == 1) {
  //  $help.dialog( "open" );
  //}

});
