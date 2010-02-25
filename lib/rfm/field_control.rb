module Rfm
  # The FieldControl object represents a field on a FileMaker layout. You can find out what field
  # style the field uses, and the value list attached to it.
  #
  # =Attributes
  #
  # * *name* is the name of the field
  #
  # * *style* is any one of:
  # * * :edit_box - a normal editable field
  # * * :scrollable - an editable field with scroll bar
  # * * :popup_menu - a pop-up menu
  # * * :checkbox_set - a set of checkboxes
  # * * :radio_button_set - a set of radio buttons
  # * * :popup_list - a pop-up list
  # * * :calendar - a pop-up calendar
  #
  # * *value_list_name* is the name of the attached value list, if any
  # 
  # * *value_list* is an array of strings representing the value list items, or nil
  #   if this field has no attached value list
  class FieldControl

    def initialize(name, style, value_list_name, value_list)
      @name = name
      case style
      when "EDITTEXT"     then @style = :edit_box
      when "POPUPMENU"    then @style = :popup_menu
      when "CHECKBOX"     then @style = :checkbox_set
      when "RADIOBUTTONS" then @style = :radio_button_set
      when "POPUPLIST"    then @style = :popup_list
      when "CALENDAR"     then @style = :calendar
      when "SCROLLTEXT"   then @style = :scrollable
      else
        nil
      end
      @value_list_name = value_list_name
      @value_list = value_list
    end
  
  end
end