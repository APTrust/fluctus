require "spec_helper"

describe InstitutionsController do
  describe "routing" do

    it "routes to #index" do
      get("/institutions").should route_to("institutions#index")
    end

    it "routes to #new" do
      get("/institutions/new").should route_to("institutions#new")
    end

    it "routes to #show" do
      get("/institutions/test").should route_to("institutions#show", :institution_identifier => "test")
    end

    it "routes to #edit" do
      get("/institutions/test/edit").should route_to("institutions#edit", :institution_identifier => "test")
    end

    it "routes to #create" do
      post("/institutions").should route_to("institutions#create")
    end

    it "routes to #update" do
      put("/institutions/test").should route_to("institutions#update", :institution_identifier => "test")
    end

    it "routes to #destroy" do
      delete("/institutions/test").should route_to("institutions#destroy", :institution_identifier => "test")
    end

  end
end
