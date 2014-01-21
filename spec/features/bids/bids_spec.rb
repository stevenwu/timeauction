require 'spec_helper'

describe "bids" do
  subject { page }

  let!(:creator) { FactoryGirl.create :user }
  let!(:auction) { FactoryGirl.create :auction_with_rewards, :rewards_count => 2, :user => creator }

  before do
    auction.update_attributes(:target => 10)
    visit auction_path(auction)
  end

  context "not logged in" do
    it "opens signup modal", :js => true do
      all(".bid-button").first.click
      page.should have_selector('#signup-modal', visible: true)
    end
  end

  context "logged in" do
    let!(:user) { FactoryGirl.create :user, :email => "johndoe@email.com" }

    before do
      facebook_login
      sleep 2
    end

    it "opens bid modal", :js => true do
      all(".bid-button").first.click
      page.should have_selector('#bid-modal', visible: true)
    end

    context "within bid modal" do
      it "shows correct reward details", :js => true do
        all(".bid-button").first.click
        page.should have_content(auction.title, visible: true)
        page.should have_content(auction.rewards.first.title, visible: true)
        page.should have_content(auction.rewards.first.description, visible: true)
        page.should have_content("#{auction.rewards.first.amount} volunteer hours", visible: true)
      end

      it "shows correct user details without first or last name", :js => true do
        all(".bid-button").first.click
        page.should have_content(user.email, visible: true)
      end

      it "shows correct user details including first or last name if provided", :js => true do
        all(".bid-button").first.click
        page.should have_content(user.email, visible: true)
        page.should have_content(user.first_name, visible: true)
        page.should have_content(user.last_name, visible: true)
      end

      it "can place bid with first and last name", :js => true do
        all(".bid-button").first.click
        sleep 1
        expect do
          click_on "Commit"
          sleep 1
        end.to change(Bid, :count).by(1)
      end

      it "cannot place bid without first and last name", :js => true do
        user.update_attributes(:first_name => "", :last_name => "")
        sleep 1
        all(".bid-button").first.click
        sleep 1
        expect do
          click_on "Commit"
          sleep 1
        end.to change(Bid, :count).by(0)
        page.should have_css(".error")
      end
    end

    context "max bidders reached on reward", :js => true do
      it "cannot bid" do
        page.should_not have_content("No more left!")
        auction.rewards.first.update_attributes(:max => 1)
        sleep 1
        all(".bid-button").first.click
        sleep 1
        click_on "Commit"
        sleep 1
        page.should have_content("No more left!")
      end
    end

    context "already bid on reward", :js => true do
      it "cannot bid" do
        all(".bid-button").first.click
        page.should_not have_content("You have already bid on this reward")
        sleep 1
        click_on "Commit"
        sleep 1
        all(".bid-button").first.click
        page.should have_content("You have already bid on this reward", visible: true)
      end
    end
  end
end