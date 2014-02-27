require 'spec_helper'

describe "premium bids" do
  subject { page }

  set(:creator) { FactoryGirl.create :user }
  set(:auction) { FactoryGirl.create :auction_with_rewards, :rewards_count => 1, :user => creator }
  set(:user) { FactoryGirl.create :user, :email => "johndoe@email.com" }

  before do
    auction.update_attributes(:target => 10)
    auction.rewards.first.update_attributes(:premium => true)
    visit auction_path(auction)
    facebook_login
    sleep 1
  end

  context "when user has not upgraded", :js => true do
    before do
      all(".bid-button").first.click
    end

    context "when reward is premium" do
      it "opens upgrade modal" do
        page.should have_selector('#upgrade-account-modal', visible: true)
      end

      context "within upgrade modal" do
        it "can click 'Upgrade'" do
          find(".upgrade-button").click
          page.should have_selector('#upgrade-payment-modal', visible: true)
        end

        it "can close modal by clicking text" do
          find(".no-thanks-on-premium").click
          page.should_not have_selector('#upgrade-account-modal', visible: true)
        end
      end

      context "within upgrade payment modal" do
        before do
          find(".upgrade-button").click
        end

        it "can close modal by clicking text" do
          sleep 1
          find(".no-thanks-on-premium").click
          sleep 1
          page.should_not have_selector('#upgrade-payment-modal', visible: true)
        end

        it "can go back a modal" do
          find(".back-on-upgrade-payment").click
          page.should have_selector('#upgrade-account-modal', visible: true)
        end

        it "can switch who to donate to" do
          find("#american-red-cross").click
          page.should have_content('https://www.redcross.org/quickdonate/index.jsp')
        end

        it "can switch the link of who to donate to" do
          find(".upgrade-payment-button")[:href].should eq("http://www.redcross.ca/donate")
          find("#american-red-cross").click
          find(".upgrade-payment-button")[:href].should eq("https://www.redcross.org/quickdonate/index.jsp")
        end

        it "upgrades the user after clicking 'Donate'" do
          find(".upgrade-payment-button").click
          sleep 1
          User.last.premium.should eq(true)
        end
      end
    end
  end

  context "when user has upgraded", :js => true do
    it "opens bid modal" do
      user.update_attributes(:premium => true)
      all(".bid-button").first.click
      page.should have_selector('#bid-modal', visible: true)
    end
  end
end