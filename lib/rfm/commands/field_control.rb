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
      when "EDITTEXT"
        @style = :edit_box
      when "POPUPMENU"
        @style = :popup_menu
      when "CHECKBOX"
        @style = :checkbox_set
      when "RADIOBUTTONS"
        @style = :radio_button_set
      when "POPUPLIST"
        @style = :popup_list
      when "CALENDAR"
        @style = :calendar
      when "SCROLLTEXT"
        @style = :scrollable
      else
        nil
      end
      @value_list_name = value_list_name
      @value_list = value_list
    end
    
    attr_reader :name, :style, :value_list_name, :value_list
  
  end
end