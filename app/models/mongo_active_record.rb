require 'bson'
require 'mongo'

class MongoActiveRecord
  include Mongo
  # static initialization
  # initialize connection to mongodb
  @@db = @@grid = nil

  def self.connection_init(config_yaml)
    @@client = MongoClient.new(config_yaml['mongo_host'], config_yaml['mongo_port'])
    @@db = @@client[config_yaml['db_name']]
    @@grid = Mongo::Grid.new(@@db)
  end

  # object instance constructor based on map of attributes (json document is good example)
  def initialize(attributes)
    @attributes = {}

    attributes.each do |parameter_name, parameter_value|
      #parameter_value = BSON::ObjectId(parameter_value) if parameter_name.end_with?("_id")
      @attributes[parameter_name] = parameter_value
    end
  end

  # handling getters and setters for object instance
  def method_missing(method_name, *args, &block)
    #puts "MongoRecord: #{method_name} - #{args.join(',')}"
    method_name = method_name.to_s; setter = false
    if method_name.end_with? '='
      method_name.chop!
      setter = true
    end

    method_name = '_id' if method_name == 'id'

    if setter
      @attributes[method_name] = args.first
    elsif @attributes.include?(method_name)
      @attributes[method_name]
    else
      nil
      #super(method_name, *args, &block)
    end
  end

  # save/update json document in db based on attributes
  # if this is new object instance - _id attribute will be added to attributes
  def save
    collection = Object.const_get(self.class.name).send(:collection)

    if @attributes.include? '_id'
      collection.update({'_id' => @attributes['_id']}, @attributes, {:upsert => true})
    else
      id = collection.save(@attributes)
      @attributes['_id'] = id
    end
  end

  def destroy
    return if not @attributes.include? '_id'

    collection = Object.const_get(self.class.name).send(:collection)
    collection.remove({ '_id' => @attributes['_id'] })
  end

  def to_s
    <<-eos
      MongoActiveRecord - #{self.class.name} - Attributes - #{@attributes}\n
    eos
  end

  #### Class Methods ####

  def self.collection_name
    raise 'This is an abstract method, which must be implemented by all subclasses'
  end

  # returns a reference to mongo collection based on collection_name abstract method
  def self.collection
    class_collection = @@db.collection(self.collection_name)
    raise "Error while connecting to #{self.collection_name}" if class_collection.nil?

    class_collection
  end

  # find by dynamic methods
  def self.method_missing(method_name, *args, &block)
    if method_name.to_s.start_with?('find_by')
      parameter_name = method_name.to_s.split('_')[2..-1].join('_')

      return self.find_by(parameter_name, args)

    elsif method_name.to_s.start_with?('find_all_by')
      parameter_name = method_name.to_s.split('_')[3..-1].join('_')

      return self.find_all_by(parameter_name, args)
    end

    super(method_name, *args, &block)
  end

  def self.all
    collection = Object.const_get(name).send(:collection)
    instances = []

    collection.find({}).each do |attributes|
      instances << Object.const_get(name).send(:new, attributes)
    end

    instances
  end

  def self.destroy(selector)
    collection = Object.const_get(name).send(:collection)

    collection.remove(selector)
  end

  private

  def self.find_by(parameter, value)
    value = value.first if value.is_a? Enumerable

    if parameter == 'id'
      value = BSON::ObjectId(value.to_s)
      parameter = '_id'
    end

    collection = Object.const_get(name).send(:collection)

    attributes = collection.find_one({ parameter => value })

    if not attributes.nil?
      Object.const_get(name).new(attributes)
    else
      nil
    end
  end

  def self.find_all_by(parameter, value)
    value = value.first if value.is_a? Enumerable

    if parameter == 'id'
      value = BSON::ObjectId(value.to_s)
      parameter = '_id'
    end

    collection = Object.const_get(name).send(:collection)

    collection.find({parameter => value}).map do |attributes|
      Object.const_get(name).new(attributes)
    end

  end

end