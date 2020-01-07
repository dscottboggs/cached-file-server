class Klass
  def self.default_action(text : String)
    "taking #{text} action"
  end

  property action : Proc(String, String | IO) = ->default_action(String)

  def on_event(&block : Proc(String, String | IO))
    @action = block
  end

  def act(data)
    @action.call data.to_s
  end
end

k = Klass.new
k.on_event do |text|
  "custom action on " + text
end

puts k.act "some text"
