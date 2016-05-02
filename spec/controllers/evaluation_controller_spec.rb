require 'rails_helper'

RSpec.describe EvaluationController, type: :controller do

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
    it "responds successfully with an HTTP 200 status code" do
      get :new
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "assigns @evaluation" do
      get :new
      expect(assigns(:evaluation)).to_not be(nil)
      expect(assigns(:evaluation).instance_of?(Evaluation)).to be(true)
    end

    it "assigns @instructor" do
      FactoryGirl.create(:instructor)
      FactoryGirl.create(:instructor)
      get :new
      expect(assigns(:instructors).count).to be(3) # number of existing instructors + "New Instructor"
    end
  end

  describe "POST #create" do
    it "redirects to the evaluation index page upon evaluation creation" do
      eval = FactoryGirl.build(:evaluation, term: '2015C')
      post :create, evaluation: eval.as_json
      expect(response).to redirect_to(evaluation_index_path(term: '2015C'))
    end

    it "creates a new evaluation if parameters are valid" do
      eval = FactoryGirl.build(:evaluation)
      expect(Evaluation.count).to eq(0)
      post :create, evaluation: eval.as_json
      expect(Evaluation.count).to eq(1)
    end

    it "creates a new instructor if necessary" do
      eval = FactoryGirl.build(:evaluation, instructor_id: 0)
      previous_evaluation_count = Evaluation.count
      previous_instructor_count = Instructor.count
      post :create, evaluation: eval.as_json.merge(instructor: "Brent Walther")
      expect(Evaluation.count).to eq(previous_evaluation_count + 1)
      expect(Instructor.count).to eq(previous_instructor_count + 1)
    end

    it "renders the new page again if params are invalid" do
      eval = FactoryGirl.build(:evaluation, term: "summer")
      post :create, evaluation: eval.as_json
      expect(response).to render_template(:new)
    end

    it "does not create an evaluation if parameters are invalid" do
      eval = FactoryGirl.build(:evaluation, term: "summer")
      previous_evaluation_count = Evaluation.count
      post :create, evaluation: eval.as_json
      expect(Evaluation.count).to eq(previous_evaluation_count)
    end
  end

  describe "GET #index" do
    it "redirects to the root path if no data exists" do
      get :index
      expect(response).to redirect_to(root_path)
    end

    it "redirects to the EvaluationController#show with the latest term if no params are given" do
      FactoryGirl.create(:evaluation, term: "2015C")
      FactoryGirl.create(:evaluation, term: "2014C")
      get :index
      expect(response).to redirect_to(evaluation_path(id: "2015C"))
    end

    it "redirects to EvaluationController#show with the passed term parameter if present" do
      FactoryGirl.create(:evaluation, term: "2015C")
      FactoryGirl.create(:evaluation, term: "2014C")
      get :index, term: "2014C"
      expect(response).to redirect_to(evaluation_path(id: "2014C"))
    end
  end

  describe "GET #show" do
    it "assigns @evaluations" do
        eval1 = FactoryGirl.create(:evaluation, course: 110, term: '2015C')
        eval2 = FactoryGirl.create(:evaluation, course: 111, term: '2015C')
        eval3 = FactoryGirl.create(:evaluation, course: 111, term: '2014C')
        get :show, id: '2015C'
        expect(assigns(:evaluation_groups)).to eq([[eval1], [eval2]])
    end

    it "assigns @terms" do
      eval1 = FactoryGirl.create(:evaluation, term: '2015C')
      eval2 = FactoryGirl.create(:evaluation, term: '2015B')
      eval3 = FactoryGirl.create(:evaluation, term: '2015B')
      get :show, id: '2015C'
      expect(assigns(:terms)).to include(eval1.term)
      expect(assigns(:terms)).to include(eval2.term)
      expect(assigns(:terms).length).to be(2) # should only include unique terms!
    end
  end

  describe "GET #import" do
    it "renders the pretty centered form template" do
      get :import
      expect(response).to render_template 'layouts/centered_form'
    end
  end

  describe "GET #export" do
    before :each do
      instructor = FactoryGirl.create(:instructor)
      FactoryGirl.create(:evaluation, term: '2015C', section: '501', enrollment: '25', item1_mean: '4.5', instructor_id: instructor.id)
      FactoryGirl.create(:evaluation, term: '2015C', section: '502', enrollment: '25', item1_mean: '4.5', instructor_id: instructor.id)
      FactoryGirl.create(:evaluation, term: '2015B', section: '501', enrollment: '25', item1_mean: '4.5', instructor_id: instructor.id)
    end

    it "generates a valid CSV file" do
      get :export, id: '2015C'
      expect { CSV.parse(response.body) }.to_not raise_error
    end

    it "only exports records for the term selected" do
      get :export, id: '2015C'
      csv = CSV.parse(response.body)
      expect(csv.size).to eq(5)
    end

    it "exports a row of average and sum functions" do
      get :export, id: '2015C'
      csv = CSV.parse(response.body)
      expect(csv[3][5]).to eq("50") # total enrollment
      expect(csv[3][6]).to eq("4.5") # average item1_mean
    end

    it "exports an empty row after each group" do
      get :export, id: '2015C'
      csv = CSV.parse(response.body)
      row5 = csv[4]
      row5.each { |val| expect(val).to eq("") }
    end
  end


  describe "GET #edit" do
    it "renders the edit template" do
      FactoryGirl.create(:evaluation)
      get :edit, id: 1
      expect(response).to render_template("evaluation/edit")
    end
  end

  describe "GET #missing_data" do
    it "shows the evaluation data for the courses with missing data" do
      FactoryGirl.create(:evaluation, course: 210)
      FactoryGirl.create(:evaluation, course: 110, enrollment: '')
      FactoryGirl.create(:evaluation, course: 454, item1_mean: '')
      get :missing_data
      expect(response).to render_template("evaluation/missing_data")
      expect(assigns(:evaluation_groups).count).to be(2)
    end
  end


  describe "PUT #update" do
    before :each do
      @eval1 = FactoryGirl.create(:evaluation, enrollment: 47)
      @eval2 = FactoryGirl.create(:evaluation, enrollment: 22)
    end

    it "updates the enrollment and redirects to evaluation page  " do
      put :update, id: @eval1, :evaluation=>{:enrollment=>"44"}
      @eval1.reload
      expect(@eval1.enrollment).to eq (44)
      expect(response).to redirect_to("/evaluation/#{@eval1.term}")
    end


    it "edits the correct row and redirects to evaluation page" do
      put :update, id: @eval1, :evaluation=>{:enrollment=>"54"}
      @eval1.reload
      @eval2.reload
      expect(@eval1.enrollment).to eq (54)
      expect(@eval2.enrollment).to eq (22)
      expect(response).to redirect_to("/evaluation/#{@eval1.term}")
    end

    it "rejects and redirects back to edit for bad updates" do
      put :update, id: @eval1, evaluation: { enrollment: "45.5" }
      @eval1.reload
      expect(@eval1.enrollment).to eq(47)
      expect(response).to render_template("evaluation/edit")
    end
  end

  describe "POST #upload" do
    it "fails gracefully for non .xlsx fils" do
      @file = fixture_file_upload('/random.dat', 'application/octet-stream')
      post :upload, data_file: @file
      expect(response).to redirect_to(import_evaluation_index_path)
      expect(flash[:errors]).to_not be(nil)
    end

    it "gracefully rejects malformatted .xlsx files" do
      @file = fixture_file_upload('/StatisticsReport_withoutCourseColumn.xlsx', 'application/vnd.ms-excel')
      post :upload, data_file: @file
      expect(response).to redirect_to(import_evaluation_index_path)
      expect(flash[:errors]).to_not be(nil)
    end

    it "accepts .xlsx files for uploading" do
      @file = fixture_file_upload('/StatisticsReport.xlsx', 'application/vnd.ms-excel')
      post :upload, data_file: @file
      expect(response).to redirect_to("/evaluation")
    end

    it "creates evaluation records for data the test file" do
      @file = fixture_file_upload('/StatisticsReport.xlsx', 'application/vnd.ms-excel')
      expect(Evaluation.count).to eq(0)
      post :upload, data_file: @file
      expect(Evaluation.count).to eq(9)
    end

    it "creates instructor records for data the test file" do
      @file = fixture_file_upload('/StatisticsReport.xlsx', 'application/vnd.ms-excel')
      expect(Instructor.count).to eq(0)
      post :upload, data_file: @file
      expect(Instructor.count).to eq(3)
    end

    it "creates the correct evaluation records for the test data" do
      @file = fixture_file_upload('/StatisticsReport.xlsx', 'application/vnd.ms-excel')
      expect(Evaluation.count).to eq(0)
      post :upload, data_file: @file
      expect(Evaluation.where(term: '2015C').count).to eq(9)
      expect(Evaluation.where(subject: 'CSCE').count).to eq(9)
      expect(Evaluation.where(course: '131').count).to eq(6)

      instructor_brent = Instructor.where(name: Instructor.normalize_name('Brent Walther')).first
      expect(Evaluation.where(instructor_id: instructor_brent).count).to eq(3)
    end
  end

  describe "GET #import_gpr" do
    it "renders the pretty centered form template" do
      get :import_gpr
      expect(response).to render_template 'layouts/centered_form'
    end
  end

  describe "POST #upload_gpr" do
    it "fails gracefully for non .pdf fils" do
      @file = fixture_file_upload('/random.dat', 'application/octet-stream')
      post :upload_gpr, data_file: @file, term: '2015C'
      expect(response).to redirect_to(import_gpr_evaluation_index_path)
      expect(flash[:errors]).to_not be(nil)
    end

    it "fails gracefully if term is missing" do
      @file = fixture_file_upload('/grade_distribution.pdf', 'application/pdf')
      post :upload_gpr, data_file: @file
      expect(response).to redirect_to(import_gpr_evaluation_index_path)
      expect(flash[:errors]).to_not be(nil)
    end

    it "accepts .pdf files for uploading" do
      @file = fixture_file_upload('/grade_distribution.pdf', 'application/pdf')
      post :upload_gpr, data_file: @file, term: '2015C'
      expect(response).to redirect_to("/evaluation")
    end

    it "creates evaluation records for each GPR found for CSCE classes" do
      @file = fixture_file_upload('/grade_distribution.pdf', 'application/pdf')
      post :upload_gpr, data_file: @file, term: '2015C'
      expect(Evaluation.count).to eq(11)
    end

    it "creates evaluation records for ENGR classes with CSCE instructors" do
      FactoryGirl.create(:instructor, name: 'Bettati R')
      @file = fixture_file_upload('/grade_dist_with_bettati.pdf', 'application/pdf')
      post :upload_gpr, data_file: @file, term: '2015C'
      expect(Evaluation.count).to eq(1)
    end
  end


end
