require 'csv'

class InstructorReportExporter
  include ApplicationHelper
  include InstructorHelper

  HEADINGS = [
    "Undergraduate and Graduate Courses Taught",
    "Semester",
    "No. of Students Enrolled",
    "Mean Student Evaluation Score",
    "Dept Avg Student Evaluation Score for Equivalent Level Courses",
    "Avg. Numerical Grade Earned by Students"
  ]

  def initialize(instructor,evaluation_groups)
    @instructor = instructor
    @course_groups = instructor.course_section_groups
    @evaluation_groups = evaluation_groups
  end

  def generate
    CSV.generate do |csv|
      csv << HEADINGS
      @course_groups.each do |courses|
        course_data = []
        course_data.push(course_name_for(courses.first))
        course_data.push(courses.first.term)
        course_data.push(compute_total_enrollment(courses))
        course_data.push(compute_mean_student_eval_score(courses).round(2))
        course_data.push(compute_course_level_average(courses,@evaluation_groups).round(2))
        course_data.push(compute_mean_gpr(courses).try(:round,2))
        csv << course_data
      end
    end
  end
end
