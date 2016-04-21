class EvaluationController < ApplicationController

  before_action :authenticate_user!

  def new
    @evaluation = Evaluation.new
    # pluck call must remain :name, :id to have the correct ordering for the select box helper
    @instructors = Instructor.select_menu_options
    render layout: "layouts/centered_form"
  end

  def create
    key_attrs, other_attrs = split_attributes(evaluation_params)

    @evaluation = Evaluation.where(key_attrs).first_or_initialize
    @evaluation.assign_attributes(other_attrs)
    @evaluation.save

    if @evaluation.errors.empty?
      flash[:notice] = "Evaluation created."
      redirect_to evaluation_index_path(term: @evaluation.term)
    else
      flash[:errors] = @evaluation.errors
      @instructors = Instructor.select_menu_options
      render 'new', layout: "layouts/centered_form"
    end
  end

  def index
    latest_term = params[:term] || Evaluation.no_missing_data.pluck(:term).uniq.sort.reverse.first
    if latest_term.nil?
      flash[:notice] = "No evaluation data exists yet! Try importing some."
      redirect_to root_path
    else
      redirect_to evaluation_path(id: latest_term)
    end
  end

  def show
    term = params[:id] || Evaluation.no_missing_data.pluck(:term).uniq.sort.reverse.first
    @evaluation_groups = Evaluation.no_missing_data.where(term: term).default_sorted_groups
    @terms = Evaluation.pluck(:term).uniq.sort.reverse
  end

  def missing_data
    @evaluation_groups = Evaluation.missing_data.default_sorted_groups
  end

  def import
    render layout: "layouts/centered_form"
  end

  def import_gpr
    render layout: "layouts/centered_form"
  end

  def export
    term = params.require(:id)
    evaluation_groups = Evaluation.no_missing_data.where(term: term).default_sorted_groups
    send_data EvaluationReportExporter.new(evaluation_groups).generate, filename: "#{term}_evaluation_report_#{Time.now.strftime('%F')}.csv"
  end

  def edit
    @evaluation = Evaluation.find(evaluation_id)
    render layout: "layouts/centered_form"
  end

  def update
    @evaluation = Evaluation.find(evaluation_id)
    @evaluation.update(evaluation_params)
    if @evaluation.errors.empty?
      flash[:notice] = "Evaluation updated."
      redirect_to evaluation_index_path
    else
      flash[:errors] = @evaluation.errors
      render 'edit'
    end
  end

  # TODO: clean this up a little but. It should be easy to follow, but it's a little long.
  def upload
    if params[:data_file] != nil
      importer = ::PicaReportImporter.new(params.require(:data_file).tempfile)
      creation_results = importer.evaluation_hashes.map do |eval_attrs|
        key_attrs, other_attrs = split_attributes(eval_attrs)

        Evaluation.create_if_needed_and_update(key_attrs, other_attrs)
      end
      num_new_records = creation_results.count { |result| result == true }
      num_updated_records = creation_results.length - num_new_records

      flash[:notice] = "#{num_new_records} new evaluations imported. #{num_updated_records} evaluations updated."
      redirect_to evaluation_index_path
    else
      flash[:errors] = "File not attached, please select file to upload"
      redirect_to import_evaluation_index_path
    end
  rescue ::PicaReportImporter::MalformedFileException => ex
    flash[:errors] = ex.to_s
    redirect_to import_evaluation_index_path
  rescue
    flash[:errors] = "There was an error parsing that XLSX file. Maybe it is corrupt?"
    redirect_to import_evaluation_index_path
  end

  def upload_gpr
    if params[:term] && params[:term].match(/\A[12][0-9]{3}[A-Z]\z/) && params[:data_file] != nil
      importer = ::GradeDistributionReportImporter.new(params.require(:data_file).tempfile, params[:term])
      creation_results = importer.grades_hashes.map do |gpr_attrs|
        key_attrs, other_attrs = split_attributes(gpr_attrs)

        Evaluation.create_if_needed_and_update(key_attrs, other_attrs)
      end

      num_new_records = creation_results.count { |result| result == true }
      num_updated_records = creation_results.length - num_new_records

      flash[:notice] = "#{num_new_records} new GPRs imported. #{num_updated_records} evaluation GPRs updated."
      redirect_to evaluation_index_path
    elsif params[:data_file] != nil
      flash[:errors] = "Term is either missing or in the incorrect format."
      redirect_to import_gpr_evaluation_index_path
    else
      flash[:errors] = "File not attached, please select file to upload"
      redirect_to import_gpr_evaluation_index_path
    end
  rescue PDF::Reader::MalformedPDFError => ex
    flash[:errors] = "There was an error parsing that PDF file. Maybe it is corrupt?"
    redirect_to import_gpr_evaluation_index_path
  end

  private
  def split_attributes(all_attrs)
      # key attributes are ones for which we should have one unique record for a set of them
      key_attributes = all_attrs.select { |k,v| [:term, :subject, :course, :section].include?(k.to_sym) }

      # other atttributes are ones that should either be assigned or updated
      other_attributes = all_attrs.select { |k,v| ![:term, :subject, :course, :section].include?(k.to_sym) }
      if other_attributes[:instructor] && !other_attributes[:instructor].instance_of?(Instructor) && !other_attributes[:instructor].empty?
        other_attributes[:instructor] = Instructor.where(name: other_attributes[:instructor]).first_or_create
      elsif other_attributes[:instructor_id] && other_attributes[:instructor_id] != "0"
        other_attributes[:instructor] = Instructor.where(id: other_attributes[:instructor_id]).first
        other_attributes.delete(:instructor_id)
      end

      [ key_attributes, other_attributes ]
  end

  def evaluation_params
    params.require(:evaluation).permit(:term, :subject, :course, :section, :instructor_id,
      :enrollment, :item1_mean, :item2_mean, :item3_mean, :item4_mean, :item5_mean,
      :item6_mean, :item7_mean, :item8_mean, :instructor)
  end

  def evaluation_id
    params.require(:id)
  end
end
