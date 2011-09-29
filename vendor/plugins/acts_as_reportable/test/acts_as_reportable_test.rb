class Array
  def to_table(columns)
    Table(columns) { |t| each { |r| t << r } }    
  end
end
    

#!/usr/bin/env ruby -w
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

begin
  require "mocha"
  require "stubba"      
  Ruport.quiet { require "active_record" } 
rescue LoadError
  nil
end

if Object.const_defined?(:ActiveRecord) && Object.const_defined?(:Mocha)

  require "ruport/acts_as_reportable"   

  class Team < ActiveRecord::Base
    acts_as_reportable :except => 'id', :include => :players
    has_many :players
  end

  class Player < ActiveRecord::Base
    acts_as_reportable
    belongs_to :team
    belongs_to :personal_trainer
  
    def stats
      "#{name} stats"
    end
  end
  
  module SomeModule
    class PersonalTrainer < ActiveRecord::Base
      acts_as_reportable
      has_one :team
      has_many :players
    end
  end
  
  module ModelStubsSetup
    Column = ActiveRecord::ConnectionAdapters::Column
    PersonalTrainer = SomeModule::PersonalTrainer
    
    def setup
      setup_column_stubs

      @trainers = []
      @trainers << PersonalTrainer.new(:name => "Trainer 1")
      @trainers << PersonalTrainer.new(:name => "Trainer 2")
      @teams = []
      @teams << Team.new( :name   => "Testers",
                          :league => "My League")
      @teams << Team.new( :name   => "Others",
                          :league => "Other League")
      @players = []
      @players << Player.new( :team_id  => 1,
                              :name     => "Player 1",
                              :personal_trainer_id  => 1)
      @players << Player.new( :team_id  => 1,
                              :name     => "Player 2",
                              :personal_trainer_id  => 2)
    
      setup_find_stubs
    end
    
    private
    
    def setup_column_stubs
      PersonalTrainer.stubs(:columns).returns([
        Column.new("id", nil, "integer", false),
        Column.new("name", nil, "string", false)])
      Team.stubs(:columns).returns([Column.new("id", nil, "integer", false),
        Column.new("name", nil, "string", false),
        Column.new("league", nil, "string", true)])
      Player.stubs(:columns).returns([Column.new("id", nil, "integer", false),
        Column.new("team_id", nil, "integer", true),
        Column.new("name", nil, "string", false),
        Column.new("personal_trainer_id", nil, "integer", true)])
    end
  
    def setup_find_stubs
      PersonalTrainer.stubs(:find).returns(@trainers)
      @trainers[0].stubs(:players).returns([@players[0]])
      @trainers[1].stubs(:players).returns([@players[1]])
      Team.stubs(:find).returns(@teams)
      @teams[0].stubs(:players).returns(@players)
      @teams[1].stubs(:players).returns([])
      Player.stubs(:find).returns(@players)
      Player.stubs(:find_by_sql).returns(@players)
      @players[0].stubs(:team).returns(@teams[0])
      @players[1].stubs(:team).returns(@teams[0])
      @players[0].stubs(:personal_trainer).returns(@trainers[0])
      @players[1].stubs(:personal_trainer).returns(@trainers[1])
    end
  end


  class TestActsAsReportableClassMethods < Test::Unit::TestCase
    
    def test_aar_options_set
      assert_equal({:except => 'id', :include => :players}, Team.aar_options)
    end
  end

  class TestActsAsReportableSingletonMethods < Test::Unit::TestCase
    include ModelStubsSetup
    
    def test_basic_report_table
      actual = Player.report_table
      expected = [[1, "Player 1", 1],
        [1, "Player 2", 2]].to_table(%w[team_id name personal_trainer_id])
      assert_equal expected, actual
    end
    
    def test_report_table_by_sql
      actual = Player.report_table_by_sql("SELECT * FROM players")
      expected = [[1, "Player 1", 1],
        [1, "Player 2", 2]].to_table(%w[team_id name personal_trainer_id])
      assert_equal expected, actual
    end
    
    def test_only_option
      actual = Player.report_table(:all, :only => 'name')
      expected = [["Player 1"],["Player 2"]].to_table(%w[name])
      assert_equal expected, actual
    end
    
    def test_only_option_preserves_column_sort_order
      column_order = %w[name personal_trainer_id team_id]
      actual = Player.report_table(:all, :only => column_order)
      expected = [["Player 1", 1, 1],
        ["Player 2", 2, 1]].to_table(column_order)
      assert_equal expected, actual
    end
      
    def test_only_option_allows_symbols
      column_order = [:name, :personal_trainer_id, :team_id]
      actual = Player.report_table(:all, :only => column_order)
      expected = [["Player 1", 1, 1],
        ["Player 2", 2, 1]].to_table(%w[name personal_trainer_id team_id])
      assert_equal expected, actual
    end
      
    def test_except_option
      actual = Player.report_table(:all, :except => 'personal_trainer_id')
      expected = [[1, "Player 1"],[1, "Player 2"]].to_table(%w[team_id name])
      assert_equal expected, actual
    end
      
    def test_methods_option
      actual = Player.report_table(:all, :only => 'name', :methods => :stats)
      expected = [["Player 1", "Player 1 stats"],
                  ["Player 2", "Player 2 stats"]].to_table(%w[name stats])
      assert_equal expected, actual
    end
      
    def test_include_option
      actual = Player.report_table(:all, :only => 'name',
        :include => :personal_trainer)
      expected = [["Player 1", "Trainer 1"],
        ["Player 2", "Trainer 2"]].to_table(%w[name personal_trainer.name])
      assert_equal expected, actual
    end
    
    def test_column_sorting_works_with_include_option  
      actual = Player.report_table(:all,
        :only     => %w[name personal_trainer.name],
        :include  => { :personal_trainer => { :only => %w[name] } })
      expected = [["Player 1", "Trainer 1"],
        ["Player 2", "Trainer 2"]].to_table(%w[name personal_trainer.name])
      assert_equal expected, actual
      
      actual = Player.report_table(:all,
        :only     => %w[personal_trainer.name name],
        :include  => { :personal_trainer => { :only => %w[name] } })
      expected = [["Trainer 1", "Player 1"],
        ["Trainer 2", "Player 2"]].to_table(%w[personal_trainer.name name])
      assert_equal expected, actual
    end
      
    def test_include_has_options
      actual = Team.report_table(:all, :only => 'name',
        :include => { :players => { :only => 'name' } })
      expected = [["Testers", "Player 1"],
        ["Testers", "Player 2"],
        ["Others", nil]].to_table(%w[name players.name])
      assert_equal expected, actual
    end
    
    class CustomRecord < Ruport::Data::Record; end

    def test_record_class_option
      actual = Player.report_table(:all, :record_class => CustomRecord)
      actual.each { |r| assert_equal CustomRecord, r.class }

      actual = Player.report_table_by_sql("SELECT * FROM players",
                 :record_class => CustomRecord)
      actual.each { |r| assert_equal CustomRecord, r.class }
    end

    def test_get_include_for_find
      assert_equal :players, Team.send(:get_include_for_find, nil)
      assert_equal nil, Player.send(:get_include_for_find, nil)
      assert_equal :team, Player.send(:get_include_for_find, :team)
      expected = {:team => {}}
      assert_equal expected,
        Player.send(:get_include_for_find, {:team => {:except => 'id'}})
      expected = {:team => {:a => {}, :b => {}},
        :c => {:d => {:e => {}, :f => {}}},
        :g => {}}
      assert_equal expected,
        Player.send(:get_include_for_find, {:team => {:include => [:a,:b]},
        :c => {:include => {:d => {:include => [:e,:f]}}}, :g => {}})
    end  
  end
    
  class TestActsAsReportableInstanceMethods < Test::Unit::TestCase
    include ModelStubsSetup
    
    def test_reportable_data
      actual = @players[0].reportable_data
      expected = [{ 'team_id' => 1,
                    'name' => "Player 1",
                    'personal_trainer_id' => 1 }]
      assert_equal expected, actual
    
      actual = @teams[0].reportable_data(:include =>
        { :players => { :only => 'name' } })
      expected = [{ 'name' => "Testers",
                    'league' => "My League",
                    'players.name' => "Player 1" },
                    { 'name' => "Testers",
                    'league' => "My League",
                    'players.name' => "Player 2" }]
      assert_equal expected, actual
    end
    
    def test_add_includes
      actual = @players[0].send(:add_includes,
        [{ 'name' => "Player 1" }], :personal_trainer)
      expected = [{ 'name' => "Player 1",
                    'personal_trainer.name' => "Trainer 1" }]
      assert_equal expected, actual
    end
    
    def test_has_report_options
      assert @teams[0].send(:has_report_options?, { :only => 'name' })
      assert @teams[0].send(:has_report_options?, { :except => 'name' })
      assert @teams[0].send(:has_report_options?, { :methods => 'name' })
      assert @teams[0].send(:has_report_options?, { :include => 'name' })
      assert !@teams[0].send(:has_report_options?, { :foo => 'name' })
    end
      
    def test_get_attributes_with_options
      actual = @players[0].send(:get_attributes_with_options)
      expected = { 'team_id' => 1,
                   'name' => "Player 1",
                   'personal_trainer_id' => 1 }
      assert_equal expected, actual
    
      actual = @players[0].send(:get_attributes_with_options,
        { :only => 'name' })
      expected = { 'name' => "Player 1" }
      assert_equal expected, actual
    
      actual = @players[0].send(:get_attributes_with_options,
        { :except => 'personal_trainer_id' })
      expected = { 'team_id' => 1,
                   'name' => "Player 1" }
      assert_equal expected, actual
    
      actual = @players[0].send(:get_attributes_with_options,
        { :only => 'name', :qualify_attribute_names => :players })
      expected = { 'players.name' => "Player 1" }
      assert_equal expected, actual
    end
  end

else
  $stderr.puts "Warning: Mocha and/or ActiveRecord not found -- skipping AAR tests"
end
