class CourseNameController < ApplicationController

  before_action :authenticate_user!

  def new
    @course_name = CourseName.where(subject_course: subject_course).first_or_initialize
    render layout: "layouts/centered_form"
  end

  def create
    @course_name = CourseName.where(subject_course: subject_course).first_or_initialize
    @course_name.assign_attributes(course_name_param)
    @course_name.save if @course_name.valid?

    if @course_name.errors.empty?
      flash[:notice] = "Course Name created."
      return_to_or_redirect_to(evaluation_index_path)
    else
      flash[:errors] = @course_name.errors
      render 'new', layout: "layouts/centered_form"
    end
  end

  def index
    @courses = Evaluation.all.group_by { |e| e.subject.to_s + e.course.to_s }.map(&:last).map(&:first)
  end

  private
  def subject_course
    if params[:course_name].nil?
      params.require(:subject_course)
    else
      params[:course_name].require(:subject_course)
    end
  end

  def course_name_param
    params.require(:course_name).permit(:name)
  end
end
