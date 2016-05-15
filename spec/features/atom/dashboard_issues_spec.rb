require 'spec_helper'

describe "Dashboard Issues Feed", feature: true  do
  describe "GET /issues" do
    let!(:user)         { create(:user) }
    let!(:project1)     { create(:project) }
    let!(:project2)     { create(:project) }
    let!(:milestone1)   { create(:milestone, project: project1, title: 'v1') }
    let!(:label1)       { create(:label, project: project1, title: 'label1') }
    let!(:issue1)       { create(:issue, author: user, assignee: user, project: project1, milestone: milestone1) }
    let!(:issue2)       { create(:issue, author: user, assignee: user, project: project2, description: 'test desc') }

    before do
      project1.team << [user, :master]
      project2.team << [user, :master]
      issue1.labels << label1
    end

    describe "atom feed" do
      it "should render atom feed via private token" do
        visit issues_dashboard_path(:atom, private_token: user.private_token)

        expect(response_headers['Content-Type']).
          to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{user.name} issues")

        entry_1 = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue1.title}')]")
        expect(entry_1).to be_present

        entry_2 = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue2.title}')]")
        expect(entry_2).to be_present

        expect(entry_1).to have_selector('author email', text: issue1.author_email)
        expect(entry_1).to have_selector('assignee email', text: issue1.author_email)
        expect(entry_1).to have_selector('labels label', text: label1.title)
        expect(entry_1).to have_selector('milestone', text: milestone1.title)
        expect(entry_1).not_to have_selector('description')

        expect(entry_2).to have_selector('author email', text: issue2.author_email)
        expect(entry_2).to have_selector('assignee email', text: issue2.author_email)
        expect(entry_2).not_to have_selector('labels')
        expect(entry_2).not_to have_selector('milestone')
        expect(entry_2).to have_selector('description', text: issue1.description)
      end
    end
  end
end
