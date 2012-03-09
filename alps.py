#!/usr/bin/python
import os, sys, socket, time, cgi, json
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from optparse import OptionParser
import sqlite3

# **********************************************************************
# Parameters
# **********************************************************************

#Database
databaseCreation = """
BEGIN TRANSACTION;
  CREATE TABLE tab (idsys INTEGER PRIMARY KEY, name TEXT);
  CREATE TABLE component (idsys INTEGER PRIMARY KEY, name TEXT, idtab NUMERIC, comment TEXT, ord NUMERIC);
  CREATE TABLE shortcut (idsys INTEGER PRIMARY KEY, name TEXT, idcomponent NUMERIC, command TEXT);
  CREATE TABLE configuration (idsys INTEGER PRIMARY KEY, name TEXT, width NUMERIC, height NUMERIC, background TEXT);
  INSERT INTO configuration VALUES (1, 'default', 310, 150, '/css/background.jpg');
COMMIT;"""
C_IDSYS,C_NAME,C_IDTAB,C_COMMENT,C_ORDER,C_IDCOMPONENT,C_COMMAND,C_WIDTH,C_HEIGHT,C_BACKGROUND = (0,1,2,3,4,2,3,2,3,4)

root=os.path.realpath(os.path.dirname(__file__)) + os.sep
database = root + 'alps.sqlite'
verbose=0
logging="stderr" 
address="127.0.0.1"

#Server will run until stop is set to true
stopped = False

#Exhaustive list of file that are served by the server
scripts = ["/js/jquery-1.7.1.min.js",
           "/js/jquery-ui-1.8.17.custom.min.js"]
csss    = ["/css/smoothness/jquery-ui-1.8.17.custom.css"]
images  = ["/css/background.jpg",
           "/css/smoothness/images/ui-icons_888888_256x240.png",
           "/css/smoothness/images/ui-icons_cd0a0a_256x240.png",
           "/css/smoothness/images/ui-bg_glass_75_dadada_1x400.png",
           "/css/smoothness/images/ui-bg_flat_75_ffffff_40x100.png",
           "/css/smoothness/images/ui-bg_glass_95_fef1ec_1x400.png",
           "/css/smoothness/images/ui-icons_454545_256x240.png",
           "/css/smoothness/images/ui-bg_flat_0_aaaaaa_40x100.png",
           "/css/smoothness/images/ui-icons_2e83ff_256x240.png",
           "/css/smoothness/images/ui-bg_glass_75_e6e6e6_1x400.png",
           "/css/smoothness/images/ui-bg_glass_65_ffffff_1x400.png",
           "/css/smoothness/images/ui-icons_222222_256x240.png",
           "/css/smoothness/images/ui-bg_glass_55_fbf9ee_1x400.png",
           "/css/smoothness/images/ui-bg_highlight-soft_75_cccccc_1x100.png"]


# **********************************************************************
# Function debug and log
# **********************************************************************
def debug(level,text):
  def address_string():
    return socket.getfqdn(address)
    
  def log_date_time_string():
    monthname = [None,'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    now = time.time()
    year, month, day, hh, mm, ss, x, y, z = time.localtime(now)
    s = "%02d/%3s/%04d %02d:%02d:%02d" % (
    day, monthname[month], year, hh, mm, ss)
    return s
    
  if (level <= verbose):
    message = "%s - - [%s] %s\n" % (address_string(), log_date_time_string(), text)
    if ( logging == "stderr" ):
      sys.stderr.write(message)
    else:
      logfile = open(options.logging,"a")
      logfile.write(message)
      logfile.close()

# **********************************************************************
# CLASS DatabaseManager
# **********************************************************************
class DatabaseManager():
  
  def __init__(self):
    debug(3,"function: DatabaseManager.__init__()")
    debug(2,"DatabaseManager: Connection to %s" % options.database)
    #Check if database is existing and create it if required
    if ( not os.path.exists(options.database) ):
      self.__sqlite = sqlite3.connect(options.database)
      debug(2,"DatabaseManager: Creating database")
      self.__query = self.__sqlite.cursor()
      self.__query.executescript(databaseCreation)
      self.__sqlite.close()
  
  def connect(self):
    debug(3,"function: DatabaseManager.connect()") 
    self.__sqlite = sqlite3.connect(options.database)
    self.__query = self.__sqlite.cursor()
      
  def execute(self, command, *args):
    debug(3,"function: DatabaseManager.execute()")
    debug(2,"DatabaseManager: %s  %s" % ( command, args))
    if ( verbose >=2 ) and (command.lstrip().upper().startswith("SELECT")):
      self.__query.execute(command, args)
      debug(2,"DatabaseManager: %s" % self.__query.fetchall())
    return self.__query.execute(command, args)

  def commit(self):
    debug(3,"function: DatabaseManager.commit()")
    self.__sqlite.commit()
    
  def close(self):
    debug(3,"function: DatabaseManager.close()")
    self.__sqlite.close()

# **********************************************************************
# CLASS MainPage
# **********************************************************************
class MainPage():
  "Page builber" 
  global databasemanager
  
  # ====================================================================
  # CSS
  # ====================================================================
  def css(self):
    debug(3,"function: MainPage.css()")
    componentWidth = 310;
    componentHeight = 150;
    componentButtonOffset=92;
    _css  = """
            body {
              font-family:\"Times New Roman\";
              font-size:10px;
              background-image:url('/css/background.jpg');
              background-repeat:no-repeat;
              background-size: 100%;
            }
            div.help {
              z-index:99;
              position: absolute;
              top: 5px;
              right: 10px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            div.options {
              z-index:99;
              position: absolute;
              top: 5px;
              right: 30px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            div.power {
              z-index:99;
              position: absolute;
              top: 5px;
              right: 50px;
              background-color:#FFFFFF;
              cursor: pointer;
            }

            #tabs div .deletetab {
              z-index:99;
              position: absolute;
              top: 37px;
              right: 4px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            #tabs div .edittab {
              z-index:99;
              position: absolute;
              top: 37px;
              right: 24px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            #tabs div .addcomponent {
              z-index:99;
              position: absolute;
              top: 37px;
              right: 45px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            div .componenttitle {
              z-index:99;
              position: relative;
              top: 2px;
              left: 2px;
              vertical-align:top;
            }
            div .addshortcut {
              z-index:99;
              position: relative;
              top: -14px;
              left: """+str(componentWidth-58)+"""px;
              width: 16px;
              background-color:#FFFFFF;
              cursor: pointer;
              
            }
            div.editcomponent {
              z-index:99;
              position: relative;
              top: -32px;
              left: """+str(componentWidth-38)+"""px;
              width: 16px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            div.deletecomponent {
              z-index:99;
              position: relative;
              top: -50px;
              left: """+str(componentWidth-18)+"""px;
              width: 16px;
              background-color:#FFFFFF;
              cursor: pointer;
            }
            div.title {
              text-align:center;
              color:#554433;
            }
            span.title {
              font-size:15px;
              color:#334455;
            }
            div.smallline {
              text-align:center;
            }
            a.smallline{
              text-decoration:none;
              color:#334455;
            }

            div.tabpanel {
              margin: 0px 3px 3px 3px; 
              width: 100%;
              overflow: hidden;

            }

            .componentlist { 
              list-style-type: none; 
              margin: 0; 
              padding: 0; 
            }

            .componentlist li { 
              margin: 4px 4px 0px 0; 
              padding: 1px; 
              float: left; 
              width: """+str(componentWidth)+"""px; 
              height: """+str(componentHeight)+"""px; 
            }
      
    """
    return _css
 
  # ====================================================================
  # JAVASCRIPT
  # ====================================================================
  def js(self):
    debug(3,"function: MainPage.js()")
    
    # ------------------------------------------------------------------
    # Javascript edit dialog
    # ------------------------------------------------------------------
    def editDialog(dialogName):
      debug(3,"function: MainPage.js.editDialog('%s')" % dialogName)
      return """  
        var $"""+dialogName+""" = $( \"#"""+dialogName+"""\" ).dialog({
            autoOpen: false,
            modal: true,
            buttons: {
                Update: function() {
                  """+dialogName+"""();
                  $( this ).dialog( "close" );
                },
                Cancel: function() {
                  $( this ).dialog( "close" );
                }
              },
              open: function() {
                $"""+dialogName+"""_title_input.focus();
              },
              close: function() {
                $( "form", $"""+dialogName+""" )[0].reset();
              }
            });
            
            $( "form", $"""+dialogName+""" ).submit(function() {
              """+dialogName+"""();
              $"""+dialogName+""".dialog( \"close\" );
              return false;
            });
      """
    # ------------------------------------------------------------------
    # Javascript add dialog
    # ------------------------------------------------------------------
    def addDialog(dialogName):
      debug(3,"function: MainPage.js.addDialog('%s')" % dialogName)
      return """  
        var $"""+dialogName+""" = $( \"#"""+dialogName+"""\" ).dialog({
            autoOpen: false,
            modal: true,
            buttons: {
              Add: function() {
                  """+dialogName+"""();
                  $( this ).dialog( "close" );
                },
                Cancel: function() {
                  $( this ).dialog( "close" );
                }
              },
              open: function() {
                $"""+dialogName+"""_title_input.focus();
              },
              close: function() {
                $( "form", $"""+dialogName+""" )[0].reset();
              }
            });
            
            $( "form", $"""+dialogName+""" ).submit(function() {
              """+dialogName+"""();
              $"""+dialogName+""".dialog( \"close\" );
              return false;
            });
      """
    
    # ------------------------------------------------------------------
    # Javascript delete dialog
    # ------------------------------------------------------------------
    def deleteDialog(dialogName):
      debug(3,"function: MainPage.js.deleteDialog('%s')" % dialogName)
      return """  
         var $"""+dialogName+""" = $( '."""+dialogName+"""' ).live( "click", function() { 
          $( '#"""+dialogName+"""' ).dialog({
            resizable: false,
            height:140,
            modal: true,
            buttons: {
              Cancel: function() {
                $( this ).dialog( "close" );
              },
              "Delete": function() {
                //Faire appel a un fonction dialogName()
                """+dialogName+"""() 
                $( this ).dialog( "close" );
              }
            }
          })
        });
      """

    # ------------------------------------------------------------------
    # Javascript main code
    # ------------------------------------------------------------------
    
    #Calculate the next idsys
    query=databasemanager.execute("SELECT MAX(idsys) FROM tab")
    id=0
    try:
      id = int(query.fetchone()[0])
    except:
      pass
    finally:
      id = str(id + 1)
    
    #Prepare content
    _tabContent = self.addtab("\"+tab_counter+\"").replace('\n','')
    _addtabDialog = addDialog('addtab')
    _edittabDialog = editDialog('edittab')
    _deletetabDialog = deleteDialog('deletetab')
    _addcomponentDialog = addDialog('addcomponent')
    _editcomponentDialog = editDialog('editcomponent')
    _deletecomponentDialog = deleteDialog('deletecomponent')
    _addshortcutDialog = addDialog('addshortcut')
    #_deleteshortcutDialog = deleteDialog('deleteshortcut')
    
    _js  = """
      $(function() {
        $( ".dialog-confirm" ).hide();
        
        var tab_counter = """+id+""";
        var senderId = -1;

        // ------------------------------------------------------------------
        // TAB
        // ------------------------------------------------------------------
        // add addtab dialog management        
 
        //
        var $addtab_title_input  = $( "#addtab_title");
        var $edittab_title_input = $( "#edittab_title");

        //Add tab and the default button
        var $tabs = $( "#tabs").tabs({
          tabTemplate: "<li><a href='#{href}'>#{label}</a>",
          add: function( event, ui ) {  
                 $( ui.panel ).append( " """+_tabContent+""" ");
               }
        });

        // Add "+" at the end of tabs
        function addPlus() {
          $("#tabs-ul")
            .append('<li id="add_tab_li"><a id="add_tab">+</a></li>')
              .live( "click", function() { $addtab.dialog( "open" )
                              });
        }
        addPlus();

        // Add new tab by sending a post to server
        // --- TODO ---
        // add a component in database and use json to get the info 
        // related to the data added in the row - the id of element are
        // indexed on the idsys
        function addtab() {
          var addtab_title = $addtab_title_input.val() || "Tab " + tab_counter;
          $.post("addtab" , { title: addtab_title }, function(data) { 
            $( '#add_tab_li' ).remove();
            $tabs.tabs( "add", "#tabs-" + tab_counter, addtab_title );
            $tabs.tabs("select", "#tabs-" + tab_counter);
            addPlus();
            tab_counter++;
            
          })
          .error(
            function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
          );
        }
        """+_addtabDialog+"""
        
        function deletetab() {
          var selected = $tabs.tabs('option', 'selected');
          $.post("deletetab" , { tabid: selected }, function(data) { 
                  $tabs.tabs( "remove", selected ); 
                })
            .error(
                function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
            );
        }
        """+_deletetabDialog+"""
        
        // edittab button
        $( ".edittab" ).live( "click", function() {
          senderId = $(this).attr('id').substr(8,100);
          var selected = $tabs.tabs('option', 'selected');
          $edittab_title_input.val($( "#tabs-ul>li").eq(selected).text());
          $edittab.dialog( "open" );
        });
        
        // edittab function
        function edittab() {
          $.post("edittab" , { idsys: senderId }, function(data) { 
              alert("edittab " + senderId);
                })
            .error(
              function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
          );
        }
        
        // edittab dialog
        """+_edittabDialog+"""
        
        // ---------------------------------------------------------
        // COMPONENT
        // ---------------------------------------------------------
        // componentlist
        $( ".componentlist" ).sortable({
          stop: function(event,ui) {
            $.post( "movecomponent" , 
                    { order: $(this).sortable("serialize") }, 
                    function(data) { 
                      return
                    }, "json")
            .error(
              function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
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
          $.post( "addcomponent" , 
                  { tabid: selected,
                    name: $("input#component_name").val() || "Component",   
                    comment: $("textarea#component_comment").val() || "Comment" }, 
                  function(data) { 
                    $("#componentlist-"+data.idtab)
                      .append(" """+self.addcomponent('"+data.idsys+"',
                                                      '"+data.name+"',
                                                      '"+data.comment+"').replace("\n","")+""" ");
                  }, "json")
            .error(
              function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
            );
        }
          
        // addcomponent dialog
        """+_addcomponentDialog+"""
        
        
        // deletecomponent button
        $( ".deletecomponent" ).live( "click", function() {
          senderId = $(this).attr('id').substr(16,100);
          $deletecomponent.dialog( "open" );
        });
        
        // deletecomponent function
        function deletecomponent() {
          $.post("deletecomponent" , { idsys: senderId }, function(data) { 
            $( "#componentPanel-" + senderId).remove();
                })
            .error(
              function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
          );
        }
        
        // deletecomponent dialog
        """+_deletecomponentDialog+"""

        
        // editcomponent button
        $( ".editcomponent" ).live( "click", function() {
          senderId = $(this).attr('id').substr(14,100);
          //TODO: Update the content of the dialog with the info from the DB
          // --> It is required to do a post to get those info
          
          //Finally open the dialog
          $editcomponent.dialog( "open" );
        });
        
        // editcomponent function
        function editcomponent() {
          $.post("editcomponent" , { idsys: senderId }, function(data) { 
              alert("editcomponent " + senderId);
                })
            .error(
              function(data) { alert("Error code: " + data.status + "\\n" + data.statusText); }
          );
        }
        
        // editcomponent dialog
        """+_editcomponentDialog+"""
        
        // ---------------------------------------------------------
        // SHORTCUTS
        // ---------------------------------------------------------        
        // add addshortcut dialog management
        """+_addshortcutDialog+"""
        
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
            $help.dialog( \"open\" );
        });
        
        //if ( tab_counter == 1) {
        //  $help.dialog( \"open\" );
        //}
    
      });
    """
    return _js
    
  # ====================================================================
  # HTML add component (use to generate html and javascript)
  # ====================================================================
  def addcomponent(self, idsys, name, comment):
    debug(3,"function: MainPage.addcomponent(%s,'%s','%s')" % ( idsys, name, comment ) )
      
    _component = """
            <li class='ui-state-default' id='componentPanel-"""+str(idsys)+"""'>
              <div class='componenttitle'><b>"""+str(name)+"""</b></div>
              <div class='ui-state-default ui-corner-all addshortcut' id='addshortcut-"""+str(idsys)+"""'>
                <span class='ui-icon ui-icon-plus'></span>
              </div>
              <div class='ui-state-default ui-corner-all editcomponent' id='editcomponent-"""+str(idsys)+"""'>
                <span class='ui-icon ui-icon-pencil'></span>
              </div>
              <div class='ui-state-default ui-corner-all deletecomponent' id='deletecomponent-"""+str(idsys)+"""'>
                <span class='ui-icon ui-icon-close'></span>
              </div>
              <br><div class='tabpanel'>"""+str(comment)+"""</div>
            </li>
    """
    return _component

  
  # ====================================================================
  # HTML add tab (use to generate html and javascript)
  # ====================================================================
  def addtab(self, tabId):
    debug(3,"function: MainPage.addtab(%s)" % tabId)
      
    _componentPanel=""


    query=databasemanager.execute("SELECT * FROM component WHERE idtab=? ORDER BY ord" , tabId )

    for row in query.fetchall():
      _componentPanel += self.addcomponent(row[C_IDSYS], row[C_NAME], row[C_COMMENT])

    _content  = """
                <div class='ui-state-default ui-corner-all addcomponent'>
                  <span class='ui-icon ui-icon-plus'></span>
                </div>
                <div class='ui-state-default ui-corner-all edittab' id='edittab-"""+tabId+"""'>
                  <span class='ui-icon ui-icon-pencil'></span>
                </div>
                <div class='ui-state-default ui-corner-all deletetab'>
                  <span class='ui-icon ui-icon-close'></span>
                </div>
                <br>
                <div class='tabpanel'> 
                  <ul id='componentlist-"""+tabId+"""' class='componentlist'>
                    """+_componentPanel+"""
                  </ul>
                </div>
    """

    try:
      if ( int(tabId) >= 0):
        return """<div id='tabs-"""+tabId+"""'>"""+_content+"""</div>"""
    except:
      pass
    return _content
  
  def htmlDeleteDialog( self, id, element):
    debug(3,"function: MainPage.htmlDeleteDialog('%s','%s')" % ( id, element ))
    return """
      <div class="dialog-confirm" id='"""+id+"""' title="Delete the current """+element+"""?">
        <p>
          <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
          These """+element+""" will be permanently deleted and cannot be recovered. Are you sure?
        </p>
      </div>"""
  
  # ====================================================================
  # HTML
  # ====================================================================
  def html(self):
    debug(3,"function: MainPage.html()")
    databasemanager.connect();
    
    _page = """ 
<html>
<head>
  <title>Administrator's Landing Page Shortcuts</title>
    <link rel="stylesheet" href="/alps.css" />
  """
    for css in csss:
      _page += "  <link rel=\"stylesheet\" href=\""+css+"\" />\n"
    for script in scripts:
      _page += "  <script type=\"text/javascript\" src=\""+script+"\"></script>\n"
    _page += """
    <script type="text/javascript" src="/alps.js"></script>
</head>
<body>
  <!-- Dialog comfirm delete  tab-->
  """+self.htmlDeleteDialog("deletetab", "tab")+"""
  
  <!-- Dialog comfirm delete  tab-->
  """+self.htmlDeleteDialog("deletecomponent", "component")+"""

  <!-- Dialog addtab -->
  <div id="addtab" title="New tab">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="addtab_title">Tab Name</label>
      <input type="text" name="addtab_title" id="addtab_title" value="" class="ui-widget-content ui-corner-all" />
      </fieldset>
    </form>
  </div>
  
  <!-- Dialog edittab -->
  <div id="edittab" title="Edit tab">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="edittab_title">Tab Name</label>
      <input type="text" name="edittab_title" id="edittab_title" value="" class="ui-widget-content ui-corner-all" />
      </fieldset>
    </form>
  </div>

  <!-- Dialog addcomponent -->
  <div id="addcomponent" title="Add component">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="component_name">Component name</label>
      <input type="text" name="component_name" id="component_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <label for="component_comment">Comments</label><br>
      <textarea name="component_comment" id="component_comment">test</textarea>
      <!--textarea name="component_comment" id="component_comment" value="" class="ui-widget-content ui-corner-all"></textarea-->
      </fieldset>
    </form>
  </div>
  
  <!-- Dialog editcomponent -->
  <div id="editcomponent" title="Edit component">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="component_name">Component name</label>
      <input type="text" name="component_name" id="component_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <label for="component_comment">Shortcut list</label><br>
      </fieldset>
    </form>
  </div>
  
  <!-- Dialog addshortcut -->
  <div id="addshortcut" title="Add shortcut">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="shortcut_name">Shortcut name</label>
      <input type="text" name="shortcut_name" id="shortcut_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <label for="shortcut_comment">Comments</label><br>
      <textarea name="component_comment" id="shortcut_comment">test</textarea>
      </fieldset>
    </form>
  </div>
  
  <!--Dialog Help-->
  <div id="help" title="Help">
    <h3>Administator's Landing Page Shortcuts</h3>
    <h4>Introduction</h4>
    <p>This tool is designed for administrator that manage numerous server and needs a
    centralized fast access to each machines.
    With ALPS you will easily create a landing page with all the shorcuts you use every days.
    This shortcut can be ssh (including remote command), telnet, rdp links etc.</p>
    <h4>Usage</h4> 
    If you reach this point, congratulation, it means that you already install the web server properly.
    After reading this introduction, you can close it and add a new tab by clicking on the + on top of this page.
    Then click on the button to add a new component reachable from an ip address.
    <h4>Credit</h4>
    Developer: X@v | Tools: python, sqlite, jquery, json | Background picture: <a href="http://www.flickr.com/photos/lassi_kurkijarvi/4547648205/sizes/o/in/photostream/">Lassi Kurkijarvi</a>
  </div>

  <!--Toolbar-->  
  <div class="ui-state-default ui-corner-all power">
    <a href="stop"><span class="ui-icon ui-icon-power"></span></a>
  </div>
  <div class="ui-state-default ui-corner-all help">
    <a id="helplink"><span class="ui-icon ui-icon-help"></span></a>
  </div>
  <div class="ui-state-default ui-corner-all options">
    <a id="options"><span class="ui-icon ui-icon-wrench"></span></a>
  </div>
    
  <!--Title-->
  <div class="title">
    <span class="title">A</span>dministator's 
    <span class="title">L</span>anding 
    <span class="title">P</span>age 
    <span class="title">S</span>hortcuts
  </div>
 
  <!--Tabs-->
    <div id="tabs" >
      <ul id="tabs-ul">
 """  
    query = databasemanager.execute("SELECT * FROM tab")
    _contents = ""
    for tab in query.fetchall():
      _page += "      <li><a href=\"#tabs-%i\">%s</a></li>\n" % tab
      _contents +=  self.addtab(str(tab[0]))
      
    _page += "    </ul>\n"
    _page += _contents
    _page += """
    </div>
    <div class="smallline">
      <sup>
        <a class="smallline" href="http://code.google.com/p/alps/">
          http://code.google.com/p/alps/
        </a>
      </sup>
    </div>
  </body>
</html>
"""  
    databasemanager.close()
    return _page

# **********************************************************************
# CLASS AlpsHttpRequestHandler
# **********************************************************************
class AlpsHttpRequestHandler(BaseHTTPRequestHandler):
  "Handler managing http requests\n"
  
  def log_message(self, format, *args):
    debug(0,format%args)
        
  def do_GET(self):
    debug(3,"function: AlpsHttpRequestHandler.do_GET()")
    databasemanager.connect()
    try:
      #Define header base on file extension
      self.send_response(200)
      if ( ".css" in self.path):
        self.send_header('Content-type',  'text/css')
      elif ( ".js" in self.path):
        self.send_header('Content-type',  'text/javascript')
      else:
        self.send_header('Content-type',  'text/html')
      self.end_headers()
      
      #Stop the server
      def stop():
        debug(3,"function: AlpsHttpRequestHandler.do_GET.stop()")
        global stopped
        stopped = True
        return "<html><head><META HTTP-EQUIV='Refresh' CONTENT='0; URL=/'></head>ALPS has been stopped<html>"
      
      #Send a file (if listed in the top of this script)  
      def sendFile ():
        debug(3,"function: AlpsHttpRequestHandler.do_GET.sendFile()")
        #if the file is known, serve it  
        if ( ( self.path in scripts ) or 
             ( self.path in csss ) or
             ( self.path in images ) ):
          fileToSend = open(root + self.path)
          self.wfile.write(fileToSend.read())
          fileToSend.close()
        return ""
          
      #If the page is dynamic, construct it and sent it
      page = MainPage()
      
      #Define dynamically constructed pages available
      actions = {
      "/alps.css": page.css,
      "/alps.js":  page.js,
      "/stop":     stop,
      "/":         page.html
      }
      
      self.wfile.write( actions.get(self.path,sendFile)() )  
        
    except IOError:
      #In case of error
      self.send_error(500,'Internal error: %s' % self.path)
    databasemanager.close()

  def do_POST(self):
    debug(3,"function: AlpsHttpRequestHandler.do_POST()")
    databasemanager.connect()
    try:
      #Extract parameters sent with this post
      form = cgi.FieldStorage(
        fp=self.rfile, 
        headers=self.headers,
        environ={'REQUEST_METHOD':'POST',
                 'CONTENT_TYPE':self.headers['Content-Type'],
                })
      
      #Add a new tab in database
      def addtab():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.addTab()")
        query=databasemanager.execute("INSERT INTO tab (name) VALUES ( ? )" , form['title'].value )
        databasemanager.commit()
        query=databasemanager.execute("SELECT * FROM tab WHERE rowid=?" , query.lastrowid )
        idsys, name = query.fetchone()
        self.send_response(200)
        self.send_header('Content-type',  'application/json')
        self.end_headers()
        self.wfile.write( json.dumps({  "idsys": idsys,
                                        "name": name }) ) 
        
      #Delete defined tab from the database          
      def deletetab():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.deleteTab()")
        query=databasemanager.execute("SELECT idsys FROM tab LIMIT 1 OFFSET ?", form['tabid'].value )
        idtab=str(query.fetchone()[0])
        query=databasemanager.execute("DELETE FROM tab WHERE idsys=?", idtab )
        query=databasemanager.execute("DELETE FROM component WHERE idtab=?", idtab )
        databasemanager.commit()
        self.send_response(200)
      
      #Edit tab          
      def edittab():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.edittab()")
        self.send_response(200)        
      
      #Add a new component in database and return what was really added through json
      def addcomponent():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.addComponent()")
        self.send_response(200)
        self.send_header('Content-type',  'application/json')
        self.end_headers()
        query=databasemanager.execute("SELECT idsys FROM tab LIMIT 1 OFFSET ?" , form['tabid'].value)
        idtab = str(query.fetchone()[0])
        name = form['name'].value
        if ( name == 'Component'):
          query=databasemanager.execute("SELECT MAX(idsys) from component")
          idsys=query.fetchone()[0]
          if (idsys):
            name="Component %i" % ( idsys + 1 )
          else:
            name="Component 1"
        query=databasemanager.execute("INSERT INTO component (idtab, name, comment, ord) VALUES (?,?,?,?)", idtab, name, form['comment'].value, 99999 )
        query=databasemanager.execute("SELECT * FROM component WHERE rowid=?" , query.lastrowid)
        idsys, name, idtab, comment, order = query.fetchone()
        databasemanager.commit()
        debug(2, "RESULT = idsys: %i, name: %s, idtab: %i, comment: %s, order: %s" % (idsys,name,idtab,comment,order) )
        self.wfile.write( json.dumps({  "idsys": idsys, 
                                        "name": name, 
                                        "idtab": idtab, 
                                        "comment": comment,
                                        "order": order }) )
        
      
      #Delete component          
      def deletecomponent():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.deletecomponent()")
        self.send_response(200)
        self.send_header('Content-type',  'application/json')
        self.end_headers()
        query=databasemanager.execute("DELETE FROM component WHERE idsys=?", form['idsys'].value )
        #TODO: Delete shortcuts
        databasemanager.commit()
      
      #Edit component          
      def editcomponent():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.editcomponent()")
        self.send_response(200)
      
      #Move component          
      def movecomponent():
        debug(3,"function: AlpsHttpRequestHandler.do_POST.movecomponent()")
        self.send_response(200)
        sorted=form['order'].value.replace("componentPanel[]=","").split("&")
        order = 1
        for idsys in sorted:
          databasemanager.execute("UPDATE component SET ord=? WHERE idsys=?", order, idsys )
          order = order + 1
        databasemanager.commit()
      
      #In case of error
      def errHandler ():
        self.send_error(500,'Internal error: %s' % self.path)
      
      #Define commands available
      actions = {
        "/addtab":          addtab,
        "/edittab":         edittab,
        "/deletetab":       deletetab,
        "/addcomponent":    addcomponent,
        "/editcomponent":   editcomponent,
        "/movecomponent":   movecomponent,
        "/deletecomponent": deletecomponent
      }
      
      actions.get(self.path,errHandler)()
      
    except IOError:
     pass
    databasemanager.close()
      
# **********************************************************************
# MAIN
# **********************************************************************
def main():
  global stopped, options, database, address ,verbose, logging, databasemanager
  
  try:
    #Process command line arguments
    OptionParser.format_epilog = lambda self, formatter: self.epilog
    parser = OptionParser(version="0.0 development in progress", epilog=
"""
Official website: http://code.google.com/p/alps/

Debug level:
  1: Reserved for development
  2: Database access
  3: Internal function call

""")
    parser.add_option("-p","--port", type="int", default="8080", dest="port", 
                      help="port used by alps' web server (default=%default)")
    parser.add_option("-a","--address", default=address, dest="address", 
                      help="address used by alps' web server (default=%default)")
    parser.add_option("-d","--database", default=database, dest="database", 
                      help="database to store shortcuts (default=%default)")
    parser.add_option("-l","--logging", default=logging, dest="logging", 
                      help="logging output (default=%default)")
    parser.add_option("-v", action="count", default=verbose, dest="verbose", 
                      help="debug level (default=%default)")
    
    (options, args) = parser.parse_args()
    verbose = options.verbose
    logging = options.logging
    address = options.address
    
    debug(0,"ALPS server is starting.")
    
    #Initialize Database Manager
    databasemanager = DatabaseManager()

    #Start the web server
    stopped = False
    server = HTTPServer((options.address, options.port), AlpsHttpRequestHandler)
    while not stopped:
      server.handle_request()
  except KeyboardInterrupt:
    os.system("touch stop")
  databasemanager.close()
  debug(0,"ALPS server has been stopped")
  server.socket.close()

if __name__ == '__main__':
    main()

