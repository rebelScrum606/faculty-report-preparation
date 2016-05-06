require 'rails_helper'

RSpec.describe CourseNameController, type: :controller do

  it "redirects the user to the login page if they are unauthenticated" do
    sign_out @user
    get :index
    expect(response).to redirect_to(new_user_session_path)
  end

  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "GET #new" do
    it "responds unsuccessfully if subject_course parameter is unset" do
      expect { get :new }.to raise_error(ActionController::ParameterMissing)
    end

    it "responds successfully if the subject_course parameter is set" do
      get :new, subject_course: "CSCE 121"
      expect(response).to be_success
    end

    it "assigns a newly created CourseName if one doesn't exist for the course and subject" do
      get :new, subject_course: "CSCE 121"
      expect(assigns(:course_name).subject_course).to eq("CSCE 121")
    end

    it "assigns a loaded instance of CourseName if one matches for this course and subject" do
      cn = FactoryGirl.create(:course_name, subject_course: "CSCE 121", name: "Cool Course")
      get :new, subject_course: "CSCE 121"
      expect(assigns(:course_name)).to eq(cn)
    end

  end

  describe "POST #create" do
    it "creates a new CourseName if one doesn't exist for the course and subject and attributes are valid" do
      previous_count = CourseName.count
      post :create, course_name: { subject_course: "CSCE 121", name: "MyCoolCourse" }
      expect(CourseName.count).to eq(previous_count + 1)
    end

    it "updates a CourseName if one already exists for the course and subject" do
      cn = FactoryGirl.create(:course_name, subject_course: "CSCE 121", name: "A dreary course")
      previous_count = CourseName.count
      post :create, course_name: { subject_course: "CSCE 121", name: "MyCoolCourse" }

      cn.reload
      expect(CourseName.count).to eq(previous_count)
      expect(cn.name).to eq("MyCoolCourse")
    end

    it "renders the new template again if parameters are invalid" do
      previous_count = CourseName.count
      post :create, course_name: { subject_course: "BOGUS 9999", name: "A bogus course." }
      expect(response).to render_template('new')
      expect(CourseName.count).to eq(previous_count)
    end
  end

  describe "GET #index" do
    it "assigns all unique courses even if they don't have a course name" do
      FactoryGirl.create(:evaluation, subject: "CSCE", course: "121")
      FactoryGirl.create(:evaluation, subject: "CSCE", course: "121")
      FactoryGirl.create(:evaluation, subject: "CSCE", course: "181")
      get :index
      expect(assigns(:courses).count).to eq(2)
    end
  end
end
