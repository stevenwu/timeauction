require 'spec_helper'

describe "manage auctions" do
  subject { page }
  set(:user) { FactoryGirl.create :user, :email => "johndoe@email.com" }

  before do
    login(user)
    visit new_auction_path
    fill_in_initial_auction_fields
  end

  context "#new and #create" do
    context "submit" do
      it "successfully" do
        fill_in_latter_auction_fields
        expect do
          click_on "Submit for approval*"
        end.to change(Auction, :count).by(1)
      end

      it "shows error if not everything filled in" do
        expect do
          click_on "Submit for approval*"
        end.to change(Auction, :count).by(0)
        page.should have_css(".alert")
      end

      it "sends team@timeauction.org an email when submitted" do
        fill_in_latter_auction_fields
        click_on "Submit for approval*"
        page.should have_css("body")
        ActionMailer::Base.deliveries.last.to.should eq(["team@timeauction.org"])
      end
    end

    context "save" do
      it "saves auction without everything filled in" do
        expect do
          click_on "Save for later"
        end.to change(Auction, :count).by(1)
      end

      it "does not save empty rewards", :js => true do
        fill_in_latter_auction_fields
        all(".auction_rewards_title").each_with_index do |title, i|
          title.find("input").set("")
        end
        all(".auction_rewards_description").each_with_index do |description, i|
          description.find("textarea").set("")
        end
        click_on "Save for later"
        all(".auction_rewards_title").each do |reward_title, i|
          within reward_title do
            find("input").value.should be_blank
          end
        end
      end      
    end
  end

  context "#edit and #update" do
    set(:auction) { FactoryGirl.create :auction_with_rewards, :rewards_count => 2, :user => user }
    set(:bid_1) { FactoryGirl.create :bid, :reward_id => auction.rewards.first.id, :user_id => user.id }
    set(:bid_2) { FactoryGirl.create :bid, :reward_id => auction.rewards.last.id, :user_id => user.id }

    it "can be edited if not submitted" do
      visit edit_auction_path(auction)
      page.should have_content("Edit auction")
    end

    # it "cannot be edited once submitted" do
    #   auction.update_attributes(:submitted => true, :target => 10)
    #   visit edit_auction_path(auction)
    #   page.should_not have_content("Edit auction")
    #   page.should have_css(".alert")
    # end

    it "does not have empty reward box when just visiting edit page", :js => true do
      visit edit_auction_path(auction)
      all(".auction_rewards_title").each do |reward_title, i|
        within reward_title do
          find("input").value.should_not be_blank
        end
      end
    end
  end
end
