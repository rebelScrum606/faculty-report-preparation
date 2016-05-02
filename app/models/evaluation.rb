class Evaluation < ActiveRecord::Base
  belongs_to :instructor
  validates_associated :instructor

  # needed for rolify
  resourcify

  validates :term, presence: true, format: { with: /\A[12][0-9]{3}[A-Z]\z/,
    message: "must be in the format: xxxxY where xxxx is year and Y is semester letter. Example: 2015C" }
  validates :subject, presence: true, format: { with: /\A[A-Z]{4}\z/,
    message: "must be four capital letters." }
  validates :course, presence: true, numericality: { only_integer: true }
  validates :section, presence: true, numericality: { only_integer: true }
  validates :enrollment, numericality: { only_integer: true, allow_blank: true }
  validates :item1_mean, numericality: { allow_blank: true }
  validates :item2_mean, numericality: { allow_blank: true }
  validates :item3_mean, numericality: { allow_blank: true }
  validates :item4_mean, numericality: { allow_blank: true }
  validates :item5_mean, numericality: { allow_blank: true }
  validates :item6_mean, numericality: { allow_blank: true }
  validates :item7_mean, numericality: { allow_blank: true }
  validates :item8_mean, numericality: { allow_blank: true }

  scope :no_missing_data, -> {where.not("enrollment is NULL OR item1_mean is NULL OR item2_mean is NULL OR item3_mean is NULL OR item4_mean is NULL OR item5_mean is NULL OR item6_mean is NULL OR item7_mean is NULL OR item8_mean is NULL")}
  scope :missing_data, -> {where("enrollment is NULL OR item1_mean is NULL OR item2_mean is NULL OR item3_mean is NULL OR item4_mean is NULL OR item5_mean is NULL OR item6_mean is NULL OR item7_mean is NULL OR item8_mean is NULL OR gpr is NULL")}

  def self.create_if_needed_and_update(key_attrs, other_attrs)
    evaluation = where(key_attrs).first_or_initialize
    is_new_record = evaluation.new_record?
    evaluation.save

    evaluation.update(other_attrs)

    is_new_record
  end

  def self.default_sorted_groups
    # We group by the following things and then sort the groups in this order:
    #  - Term (2015C, 2015A, 2014C)
    #  - Subject (CSCE, ENGR)
    #  - Course (110, 111, 121)
    #  - Instructor (Williams, Hurley)
    #  - First character of section (200s, 500s are grouped together)
    all.group_by do |eval|
      eval.term.to_s + eval.subject.to_s + eval.course.to_s + eval.instructor.id.to_s + eval.section.to_s[0]
    end.sort { |group1, group2| group1.first <=> group2.first }.map(&:last)
  end

  def is_honors_section?
    section.to_s.starts_with?("2")
  end

  def subject_course
    "#{subject} #{course}"
  end

  def has_course_name?
    !course_name.nil?
  end

  def course_name
    CourseName.where(subject_course: subject_course).first.try(:name)
  end

  def csv_data
    [
      term,
      subject,
      course,
      section,
      instructor.name,
      enrollment,
      item1_mean,
      item2_mean,
      item3_mean,
      item4_mean,
      item5_mean,
      item6_mean,
      item7_mean,
      item8_mean
    ].map(&:to_s)
  end

end
