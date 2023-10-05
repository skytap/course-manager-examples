# Copyright 2023 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'lab_control'

class ExamGrader
  MULTIPLE_CHOICE_QUESTIONS = {
    'exam_q_post_name' => {
      'text' => 'What is a post called in Mastodon?',
      'answer' => 'None of the above'
    },
    'exam_q_freeze' => {
      'text' => 'What does it mean to "freeze" a user account in Mastodon?',
      'answer' => 'The account cannot create new content',
    },
    'exam_q_windows_client' => {
      'text' => 'What is the name of the Windows client you installed earlier?',
      'answer' => 'Whalebird',
    },
    'exam_q_max_post_length' => {
      'answer' => '500 characters',
      'text' => 'What is the maximum length of a post on Mastodon?',
    },
    'exam_q_entity_name' => {
      'text' => 'What is the name of the organization that maintains Mastodon?',
      'answer' => 'Mastodon gGmbH',
    }
  }

  def initialize
    @lab_control = LabControl.get
  end

  def grade_exam
    summary = ""
    total_score = 0 # possible scores 25 to 100

    MULTIPLE_CHOICE_QUESTIONS.each_with_index do |(key, val), index|
      user_answer = @lab_control.find_metadata_attr(key)

      score = user_answer == val['answer'] ? 10 : 0
      
      summary << <<~EOF
        Question #{ index + 1 }: #{ val['text'] }
        Correct answer: #{ val['answer'] }
        Your answer: #{ user_answer }
        Your score: #{ score }/10

      EOF

      total_score += score
    end

    troll_username = @lab_control.find_metadata_attr('troll_username')
    user_answer_troll = @lab_control.find_metadata_attr('exam_q_troll_user')

    if user_answer_troll
      troll_correct = user_answer_troll.gsub('@', '') == troll_username
      troll_score = troll_correct ? 50 : 0
      total_score += troll_score
      summary << <<~EOF
        Question 6: Enter the username of the troll you suspended
        Correct answer: #{ troll_username }
        Your answer: #{ user_answer_troll }
        Your score: #{ troll_score }/50
      EOF
    end

    {
      total_score: total_score,
      summary: summary
    }
  end
end
