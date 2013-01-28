my $verbose=0;


package Javascript;

use strict;
use POSIX;
use CGI::Session;
use Sqlite;
use Page;


sub new
{
  my $this = bless {}, shift;
  $this->{'alps'} = shift;

  $verbose = $this->{'alps'}->{'verbose'};

  $this->Debug(3,"");

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub AddDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return q[
        var $]."$dialogName".q[ = $( "#]."$dialogName".q[" ).dialog({
            autoOpen: false,
            modal: true,
            buttons: {
              Add: function() {
                  ]."$dialogName".q[();
                  $( this ).dialog( "close" );
                },
                Cancel: function() {
                  $( this ).dialog( "close" );
                }
              },
              open: function() {
                $]."$dialogName".q[_title_input.focus();
              },
              close: function() {
                $( "form", $]."$dialogName".q[ )[0].reset();
              }
            });

            $( "form", $]."$dialogName".q[ ).submit(function() {
              ]."$dialogName".q[();
              $]."$dialogName".q[.dialog( "close" );
              return false;
            });
      ];
}

sub EditDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return q[
        var $]."$dialogName".q[ = $( "#]."$dialogName".q[" ).dialog({
            autoOpen: false,
            modal: true,
            buttons: {
                Update: function() {
                  ]."$dialogName".q[();
                  $( this ).dialog( "close" );
                },
                Cancel: function() {
                  $( this ).dialog( "close" );
                }
              },
              open: function() {
                $]."$dialogName".q[_title_input.focus();
              },
              close: function() {
                $( "form", $]."$dialogName".q[ )[0].reset();
              }
            });

            $( "form", $]."$dialogName".q[ ).submit(function() {
              ]."$dialogName".q[();
              $]."$dialogName".q[.dialog( "close" );
              return false;
            });
  ];
}

sub DeleteDialog
{
  my $this=shift;
  my $dialogName = shift;
  $this->Debug(4,"");
  return q[
         var $]."$dialogName".q[ = $( '.]."$dialogName".q[' ).live( "click", function() {
          $( '#]."$dialogName".q[' ).dialog({
            resizable: false,
            height:140,
            modal: true,
            buttons: {
              Cancel: function() {
                $( this ).dialog( "close" );
              },
              "Delete": function() {
                //Faire appel a un fonction dialogName()
                ]."$dialogName".q[()
                $( this ).dialog( "close" );
              }
            }
          })
        });
  ];
}

sub Print {
  my $this = shift;
  $this->Debug(3,"");

  #Calculate the next idsys
  my $query="SELECT MAX(idsys) FROM tab";
  my $response = $this->{'alps'}->{'sqlite'}->ExecuteQuery($query);
  my $id = ($response->[0]->[0])+1 || 0;

  my $page = $this->{'alps'}->{'page'};
  my $_tabContent             = $page->AddTab("\"+tab_counter+\"");
  $_tabContent =~ s/\n//g;
  my $_addtabDialog           = $this->AddDialog('addtab');
  my $_edittabDialog          = $this->EditDialog('edittab');
  my $_deletetabDialog        = $this->DeleteDialog('deletetab');
  my $_addcomponentDialog     = $this->AddDialog('addcomponent');
  my $_editcomponentDialog    = $this->EditDialog('editcomponent');
  my $_deletecomponentDialog  = $this->DeleteDialog('deletecomponent');
  my $_addshortcutDialog      = $this->AddDialog('addshortcut');

  my $content = q]
      $(function() {

        $( ".dialog-confirm" ).hide();

        var tab_counter = ] . "$id" . q[;
        var senderId = -1;

        // ------------------------------------------------------------------
        // TAB
        // ------------------------------------------------------------------
        // add addtab dialog management

        //
        var $addtab_title_input  = $( "#addtab_title");
        var $edittab_title_input = $( "#edittab_title");

        //Add tab and the default button
        var $tabs = $( "#tabs" ).tabs({
          tabTemplate: "<li><a href='#{href}'>#{label}</a>",
          add: function( event, ui ) {
                 $( ui.panel ).append( " ]."$_tabContent".q[ ");
               },
          cookie: { expires: 365 }
        });

        // Add "+" at the end of tabs
        function addPlus() {
          $("#tabs-ul")
            //.append('<li id="tabs-0"><a id="add_tab">+</a></li>')
            .append('<li class="ui-add-tab"><a id="add_tab">+</a></li>')
              .live( "click", function() { $addtab.dialog( "open" )
                              });
        }
        addPlus();

        // Sortable tab
        $tabs.find( ".ui-tabs-nav" ).sortable({
          stop: function(event,ui) {
            var csv = "";
            $("#tabs > ul > li > a").each(function(i){
        if (this.href != "") {
          csv+= ( csv == "" ? "" : "," ) + this.href.split("-")[1];
        }
            });
      $.post( "MoveTab" ,
                    { order: csv },
                    function(data) {
                      return
                    }, "json")
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
            );
          }
        });

        // Add new tab by sending a post to server
        // --- TODO ---
        // add a component in database and use json to get the info
        // related to the data added in the row - the id of element are
        // indexed on the idsys
        function addtab() {
          var addtab_title = $addtab_title_input.val() || "tab_title";
          $.post("AddTab" , { title: addtab_title }, function(data) {
            $( ".ui-add-tab" ).remove();
            $tabs.tabs( "add", "#tabs-" + data.idsys, addtab_title );
            $tabs.tabs("select", "#tabs-" + data.idsys);
            addPlus();
            tab_counter++;
          })
          .fail(
            function(data) { alert("Error code: " + data.status + "\\n"
                                                  + data.statusText + "\\n"
                                                  + data.responseText); }
          );
        }
        ]."$_addtabDialog".q[

        function deletetab() {
          var selected = $('.ui-tabs-selected a').attr('href').split('-')[1];
          $.post("DeleteTab" , { tabid: selected }, function(data) {
                  $tabs.tabs( "remove", selected );
                })
            .fail(
                function(data) { alert("Error code: " + data.status + "\\n"
                                                      + data.statusText + "\\n"
                                                      + data.responseText); }
            );
        }
        ]."$_deletetabDialog".q[

        // edittab button
        $( ".edittab" ).live( "click", function() {
          senderId = $(this).attr('id').substr(8,100);
          var selected = $tabs.tabs('option', 'selected');
          $edittab_title_input.val($( "#tabs-ul>li").eq(selected).text());
          $edittab.dialog( "open" );
        });

        // edittab function
        function edittab() {
          $.post("EditTab" , { idsys: senderId, newtitle: $edittab_title_input.val() }, function(data) {
              var selected = $tabs.tabs('option', 'selected');
              $( "#tabs-ul>li:eq("+selected+") a").text( data.newtitle);
            }, "json")
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
          );
        }

        // edittab dialog
        ]."$_edittabDialog".q[

        // ---------------------------------------------------------
        // COMPONENT
        // ---------------------------------------------------------
        // componentlist
        $( ".componentlist" ).sortable({
          stop: function(event,ui) {
            $.post( "MoveComponent" ,
                    { order: $(this).sortable("serialize") },
                    function(data) {
                      return
                    }, "json")
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
            );
          }
        });
        $( ".componentlist" ).disableSelection();



        // addcomponent button
        $( ".addcomponent" ).live( "click", function() {
            $addcomponent.dialog( "open" );
        });

        // addcomponent function
        // Add new tab by sending a post to server
        // add a component in database and use json to get the info
        // related to the data added in the row - the id of element are
        // indexed on the idsys
        function addcomponent() {
          var selected = $tabs.tabs('option', 'selected');
          $.post( "AddComponent" ,
                  { tabid: selected,
                    name: $("input#component_name").val() || "Component",
                    comment: $("textarea#component_comment").val() || "Comment" },
                  function(data) {
                    $("#componentlist-"+data.idtab)
                      .append(" ] . $this->{'alps'}->{'page'}->AddComponent('"+data.idsys+"',
                                                                            '"+data.name+"',
                                                                            '"+data.comment+"'). q[ ");
                  }, "json")
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
            );
        }

        // addcomponent dialog
        ]."$_addcomponentDialog".q[


        // deletecomponent button
        $( ".deletecomponent" ).live( "click", function() {
          senderId = $(this).attr('id').substr(16,100);
          $deletecomponent.dialog( "open" );
        });

        // deletecomponent function
        function deletecomponent() {
          $.post("DeleteComponent" , { idsys: senderId }, function(data) {
            $( "#componentPanel-" + senderId).remove();
                })
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
          );
        }

        // deletecomponent dialog
        ]."$_deletecomponentDialog".q[


        // editcomponent button
        $( ".editcomponent" ).live( "click", function() {
          senderId = $(this).attr('id').substr(14,100);
          $("#editcomponent_name").val($("#componenttitle-"+senderId+" b").text())
          //TODO: Update the content of the dialog with the info from the DB
          // --> It is required to do a post to get those info

          //Finally open the dialog
          $editcomponent.dialog( "open" );
        });

        // editcomponent function
        function editcomponent() {
          $.post("EditComponent" , { idsys: senderId, newname: $("#editcomponent_name").val() }, function(data) {
              $("#componenttitle-"+senderId+" b").text(data.newname)
                }, "json")
            .fail(
              function(data) { alert("Error code: " + data.status + "\\n"
                                                    + data.statusText + "\\n"
                                                    + data.responseText); }
          );
        }

        // editcomponent dialog
        ]."$_editcomponentDialog".q[

        // ---------------------------------------------------------
        // SHORTCUTS
        // ---------------------------------------------------------
        // add addshortcut dialog management
        ]."$_addshortcutDialog".q[

        // Add addshortcut button
        $( ".addshortcut" )
          .click(function() {
            $addshortcut.dialog( "open" );
        });


        // Add new tab by sending a post to server
        function addshortcut() {
          alert('Adding shortcut for component '+ component);
        }


        // ---------------------------------------------------------
        // HELP
        // ---------------------------------------------------------
        var $help = $( "#help" ).dialog({
          width:900,
          autoOpen: false,
          modal: true,
          buttons: {
            Close: function() {
              $( this ).dialog( "close" );
            }
          },
          close: function() {
            $form[ 0 ].reset();
          }
        });

        $( "#helplink" )
          .click(function() {
            $help.dialog( "open" );
        });

        //if ( tab_counter == 1) {
        //  $help.dialog( "open" );
        //}

      });
    ];

}


1;
