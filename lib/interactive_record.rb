require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord

    def initialize (options={})
        options.each do |property, value|
        self.send("#{property}=", value)
        end
    end 

    def self.table_name
        ActiveSupport::Inflector.tableize(self.to_s)
    end

    def self.column_names
        DB[:conn].results_as_hash=true
        sql="PRAGMA table_info ('#{table_name}')"
        column_names=DB[:conn].execute(sql).map {|column| column["name"]}
        column_names.each {|col_name| attr_accessor col_name.to_sym}
        column_names

    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if{|col| col=="id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
        values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        self.values_for_insert
        sql= <<-SQL 
        INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) 
        VALUES (#{values_for_insert})
        SQL

        DB[:conn].execute(sql)
        @id=DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
    DB[:conn].execute("SELECT *FROM #{self.table_name} WHERE name=?",[name])

    end

    def self.find_by(hash)
        sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys[0].to_s} = '#{hash.values[0].to_s}'"
        DB[:conn].execute(sql)
    end


  
end