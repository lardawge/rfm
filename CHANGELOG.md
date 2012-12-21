## 1.4.2 (unreleased)
  
### enhancements
  * Make nil default on fields with no value.
    
    ```ruby
    record.john #=> "" 
    record.john #=> nil
    ```

## 1.4.1.2

### bug fixes
  * Pointing out why testing is soooooo important when refactoring... Found a bug in getter/setter method in Rfm::Record

## 1.4.1.1

### bug fixes
  * Inadvertently left out an attr_reader for server from resultset effecting container urls.

## 1.4.1

### enhancements
  * Changed Server#do_action to Server#connect.
  * XML Parsing is now done via xpath which significantly speeds up parsing.
  * Changes to accessor method names for Resultset#portals Resultset#fields to Resultset#portal_meta and Resultset#field_meta to better describe what you get back.
  * Added an option to load portal records which defaults to false. This significantly speeds up load time when portals are present on the layout.

    ```ruby
    # This will fetch all records with portal records attached.
    result = fm_server('layout').find({:username => "==#{username}"}, {:include_portals => true})      

    result.first.portals # return an empty hash if incude_portals is not true
    ```
    
  * Internal file restructuring. Some classes have changed but it should be nothing a developer would use API wise. Please let me know if it is.
  * Removed Layout#value_lists && Layout#field_controls. Will put back in if the demand is high. Needs a major refactor and different placement if it goes back in. Was broken so it didn't seem to be used by many devs.
