require 'minitest/autorun'
require 'ruby2js/filter/angularrb'
require 'ruby2js/filter/angular-route'

describe Ruby2JS::Filter::AngularRB do
  
  def to_js( string)
    Ruby2JS.convert(string, filters: [Ruby2JS::Filter::AngularRB,
      Ruby2JS::Filter::AngularRoute])
  end
  
  describe 'module' do
    it "should convert empty modules" do
      to_js( 'module Angular::X; end' ).
        must_equal 'const X = angular.module("X", [])'
    end

    it "should convert modules with a use statement" do
      ruby = <<-RUBY
        module Angular::PhonecatApp 
          use :PhonecatFilters
        end
      RUBY

      js = <<-JS.gsub!(/^ {8}/, '').chomp
        const PhonecatApp = angular.module("PhonecatApp", ["PhonecatFilters"])
      JS

      to_js( ruby ).must_equal js
    end
  end
  
  describe 'controllers' do
    it "should convert apps with a controller" do
      ruby = <<-RUBY
        module Angular::PhonecatApp 
          class PhoneListCtrl < Angular::Controller 
            $scope.orderProp = 'age'
          end
        end
      RUBY

      js = <<-JS.gsub!(/^ {8}/, '').chomp
        const PhonecatApp = angular.module("PhonecatApp", []);

        PhonecatApp.controller("PhoneListCtrl", function($scope) {
          $scope.orderProp = "age"
        })
      JS

      to_js( ruby ).must_equal js
    end
  end
  
  describe 'filter' do
    it "should convert apps with a filter" do
      ruby = <<-RUBY
        module Angular::PhonecatApp 
          filter :pnl do |input|
            if input < 0
              "loss"
            else
              "profit"
            end
          end
        end
      RUBY

      js = <<-JS.gsub!(/^ {8}/, '').chomp
        const PhonecatApp = angular.module("PhonecatApp", []);

        PhonecatApp.filter("pnl", function() {
          return function(input) {
            return (input < 0 ? "loss" : "profit")
          }
        })
      JS

      to_js( ruby ).must_equal js
    end
  end
  
  describe 'route' do
    it "should convert apps with a route" do
      ruby = <<-RUBY
        module Angular::PhonecatApp 
          case $routeProvider
          when '/phones'
            controller = :PhoneListCtrl
          else
            redirectTo '/phones'
          end
        end
      RUBY

      js = <<-JS.gsub!(/^ {8}/, '').chomp
        const PhonecatApp = angular.module("PhonecatApp", ["ngRoute"]);

        PhonecatApp.config([
          "$routeProvider",
        
          function($routeProvider) {
            $routeProvider.when("/phones", {controller: "PhoneListCtrl"}).otherwise({redirectTo: "/phones"})
          }
        ])
      JS

      to_js( ruby ).must_equal js
    end
  end

  describe Ruby2JS::Filter::DEFAULTS do
    it "should include AngularRB" do
      Ruby2JS::Filter::DEFAULTS.must_include Ruby2JS::Filter::AngularRB
    end

    it "should include AngularRoute" do
      Ruby2JS::Filter::DEFAULTS.must_include Ruby2JS::Filter::AngularRoute
    end
  end
end
