# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Schema::NonNull do
  let(:of_type) { Jazz::Musician }
  let(:non_null_type) { GraphQL::Schema::NonNull.new(of_type) }

  it "returns list? to be false" do
    refute non_null_type.list?
  end

  it "returns non_null? to be true" do
    assert non_null_type.non_null?
  end

  it "returns kind to be GraphQL::TypeKinds::NON_NULL" do
    assert_equal GraphQL::TypeKinds::NON_NULL, non_null_type.kind
  end

  it "returns correct type signature" do
    assert_equal "Musician!", non_null_type.to_type_signature
  end

  describe "comparison operator" do
    it "will return false if list types 'of_type' are different" do
      new_of_type = Jazz::InspectableKey
      new_non_null_type = GraphQL::Schema::NonNull.new(new_of_type)

      refute_equal non_null_type, new_non_null_type
    end

    it "will return true if list types 'of_type' are the same" do
      new_of_type = Jazz::Musician
      new_non_null_type = GraphQL::Schema::NonNull.new(new_of_type)

      assert_equal non_null_type, new_non_null_type
    end
  end

  describe "to_graphql" do
    it "will return a non null type" do
      assert_kind_of GraphQL::NonNullType, non_null_type.deprecated_to_graphql
    end
  end

  describe "double-nulling" do
    it "is a parse error in a query" do
      res = Jazz::Schema.execute "
      query($id: ID!!) {
        find(id: $id) { __typename }
      }
      "

      assert_equal ['Parse error on "!" (BANG) at [2, 21]'], res["errors"].map { |e| e["message"] }
    end
  end

  describe "Introspection" do
    class NonNullIntrospectionSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :strs, [String], null: false
      end

      query Query
    end

    it "doesn't break on description" do
      res = NonNullIntrospectionSchema.execute(<<-GRAPHQL).to_h
        query IntrospectionQuery {
          __type(name: "Query") {
            fields {
              type {
                description
                ofType {
                  description
                  ofType {
                    description
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      assert_equal [nil], res["data"]["__type"]["fields"].map { |f| f["description"] }
    end
  end
end
