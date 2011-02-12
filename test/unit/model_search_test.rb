require 'test_helper'

module Slingshot
  module Model

    class SearchTest < Test::Unit::TestCase

      context "Model::Search" do

        setup do
          @stub = stub('search') { stubs(:query).returns(self); stubs(:perform).returns(self); stubs(:results).returns([]) }
        end

        should "have the search method" do
          assert_respond_to Model::Search, :search
          assert_respond_to ActiveModelArticle, :search
        end

        should "search in specific index" do
          i = 'active_model_articles'
          q = 'foo'
          Slingshot::Search::Search.expects(:new).with(i, {}).returns(@stub)

          ActiveModelArticle.search q
        end

        should "wrap results in proper class and do not change the original wrapper" do
          response = { 'hits' => { 'hits' => [{'_id' => 1, '_source' => { :title => 'Article' }}] } }
          Configuration.client.expects(:post).returns(response.to_json)

          collection = ActiveModelArticle.search 'foo'
          assert_instance_of Results::Collection, collection

          assert_equal Results::Item, Slingshot::Configuration.wrapper

          document = collection.first
          assert_instance_of ActiveModelArticle, document
          assert_equal 'Article', document.title
        end

        context "searching with a block" do

          should "pass on whatever block it received" do
            Slingshot::Search::Search.any_instance.expects(:perform).returns(@stub)
            Slingshot::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            ActiveModelArticle.search { query { string 'foo' } }
          end

        end

        context "searching with query string" do

          setup do
            @q = 'foo AND bar'

            Slingshot::Search::Query.any_instance.expects(:string).with( @q ).returns(@stub)
            Slingshot::Search::Search.any_instance.expects(:perform).returns(@stub)
          end

          should "search for query string" do
            ActiveModelArticle.search @q
          end

          should "allow to pass :order option" do
            Slingshot::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :order => 'title'
          end

          should "allow to pass :sort option as :order option" do
            Slingshot::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :sort => 'title'
          end

          should "allow to specify sort direction" do
            Slingshot::Search::Sort.any_instance.expects(:title).with('DESC')

            ActiveModelArticle.search @q, :order => 'title DESC'
          end

          should "allow to specify more fields to sort on" do
            Slingshot::Search::Sort.any_instance.expects(:title).with('DESC')
            Slingshot::Search::Sort.any_instance.expects(:field).with('author.name', nil)

            ActiveModelArticle.search @q, :order => ['title DESC', 'author.name']
          end

        end

      end

    end

  end
end