require 'date'

module JqueryDatepicker
  module FormHelper

    include ActionView::Helpers::JavaScriptHelper

    # Mehtod that generates datepicker input field inside a form
    def datepicker(object_name, method, options = {}, timepicker = false)
      input_tag =  JqueryDatepicker::InstanceTag.new(object_name, method, self, options)
      html, dp_options = input_tag.render
      method = timepicker ? "datetimepicker" : "datepicker"

      field_id = options["id"] || input_tag.get_name_and_id["id"]
      ready_js = "jQuery('##{field_id}').#{method}(#{dp_options.to_json});"
      if dp_options.has_key?("altField")
        # http://stackoverflow.com/questions/3922592/jquery-ui-datepicker-clearing-the-altfield-when-the-primary-field-is-cleared
        ready_js = "#{ready_js}; jQuery('##{field_id}').change(function() { if (!$(this).val()) { jQuery('#{dp_options['altField']}').val(''); } });"
      end
      html += javascript_tag("jQuery(document).ready(function(){#{ready_js}});")
      html.html_safe
    end

  end

end

module JqueryDatepicker::FormBuilder
  def datepicker(method, options = {})
    @template.datepicker(@object_name, method, objectify_options(options))
  end

  def datetime_picker(method, options = {})
    @template.datepicker(@object_name, method, objectify_options(options), true)
  end
end

class JqueryDatepicker::InstanceTag < ActionView::Helpers::Tags::Base

  FORMAT_REPLACEMENTES = { "yy" => "%Y", "mm" => "%m", "dd" => "%d", "d" => "%-d", "m" => "%-m", "y" => "%y", "M" => "%b"}

  # Extending ActionView::Helpers::InstanceTag module to make Rails build the name and id
  # Just returns the options before generate the HTML in order to use the same id and name (see to_input_field_tag mehtod)

  def get_name_and_id(options = {})
    add_default_name_and_id(options)
    options
  end

  def available_datepicker_options
    ['disabled', 'altField', 'altFormat', 'appendText', 'autoSize', 'buttonImage', 'buttonImageOnly', 'buttonText', 'calculateWeek', 'changeMonth', 'changeYear', 'closeText', 'constrainInput', 'currentText', 'dateFormat', 'dayNames', 'dayNamesMin', 'dayNamesShort', 'defaultDate', 'duration', 'firstDay', 'gotoCurrent', 'hideIfNoPrevNext', 'isRTL', 'maxDate', 'minDate', 'monthNames', 'monthNamesShort', 'navigationAsDateFormat', 'nextText', 'numberOfMonths', 'prevText', 'selectOtherMonths', 'shortYearCutoff', 'showAnim', 'showButtonPanel', 'showCurrentAtPos', 'showMonthAfterYear', 'showOn', 'showOptions', 'showOtherMonths', 'showWeek', 'stepMonths', 'weekHeader', 'yearRange', 'yearSuffix']
  end

  def split_options(options)
    tf_options = options.slice!(*available_datepicker_options)
    return options, tf_options
  end

  def format_date(tb_formatted, format)
    new_format = translate_format(format)
    Date.parse(tb_formatted).strftime(new_format)
  end

  # Method that translates the datepicker date formats, defined in (http://docs.jquery.com/UI/Datepicker/formatDate)
  # to the ruby standard format (http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime).
  # This gem is not going to support all the options, just the most used.

  def translate_format(format)
    format.gsub!(/#{FORMAT_REPLACEMENTES.keys.join("|")}/) { |match| FORMAT_REPLACEMENTES[match] }
  end

  def render
    options = @options.stringify_keys
    dp_options, tf_options = split_options(options)
    tf_options['value'] = format_date(tf_options['value'], String.new(dp_options['dateFormat'])) if  tf_options['value'] && !tf_options['value'].empty? && dp_options.has_key?('dateFormat')
    add_default_name_and_id(options)
    add_default_name_and_id(tf_options)

    return tag("input", tf_options.merge("type" => "text")), dp_options
  end

  class << self
    def field_type
      @field_type ||= "text"
    end
  end

  private

  def field_type
    self.class.field_type
  end

end
