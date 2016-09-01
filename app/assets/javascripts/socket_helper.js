function add_binders() {
	dispatcher.bind('start_game', function(data) {
		response_start_game(data);
		console.log("GOT RESPONSE FROM start_game");
		console.log(data);
	})

	dispatcher.bind('get_question', function(data) {
		if (data.game_id == game_id || ( self_user_id != "" && self_user_id != null && data.game_data.users_data.indexOf(self_user_id) > -1)) {
			response_get_question(data);
			console.log("GOT RESPONSE FROM get_question");
			console.log(data);
		} else {
			console.log('Not related to our game')
		}
	})

	dispatcher.bind('final_scores', function(data) {
		if (data.game_id == game_id) {
			response_final_scores(data);
			console.log("GOT RESPONSE FROM final_scores");
			console.log(data);
		} else
			console.log('Not related to our game')

	})
}

function send_message(key, message) {
	console.log("trying to send to: " + key)
	console.log(message)
	success = function(response) {
		console.log("success in sending through socket!!!!")
	}

	failure = function(response) {
		console.log("ERROR in sending through socket")
	}
	dispatcher.trigger(key, message, success, failure);
}

// $(document).ready(function(){
//   $('button.genre').click(function(){
//     selected_genre = $(this).html();
//     console.log(selected_genre);
//     start_game();
//   });
// });

function start_game() {
	params = {
		genre: selected_genre,
		user_name: user_name,
		self_user_id: self_user_id
	}
	send_message('start_game', params);

}

function response_start_game(data) {
	if (data.status == 200 && start_game_flag == false) {
		start_game_flag = true
		var random_colors = ['#C78989', '#89C7BA', '#B389C7', '#89AFC7', '#BFC789', '#C789A7'];
		users_data = data.users_data
		$('.question .user-profile-image.user-1').css('background', random_colors[Math.floor((Math.random() * 10))]);
		$('.question .user-profile-image.user-2').css('background', random_colors[Math.floor((Math.random() * 10))]);
		$('.question .user-name.user-1').html(users_data['1'].name);
		$('.question .user-name.user-2').html(users_data['2'].name);
		game_id = data.game_id
		get_question_from_socket();
	} else if (data.status == 100 && start_game_flag == false) {
		start_game_flag = true
		users_data = data.users_data
		$('.genre-container').css('display', 'none');
		$('.waiting-container').css('display', 'block');
	} else {
		console.log('nothing to do with the following data');
		console.log(data)
	}
}

function get_user_name() {
	//user_name = prompt("prompt", "Your username");
	user_name = $('.user-name-input').val();
	self_user_id = user_name + "_" + Math.floor((Math.random() * 100000) + 1).toString();
	if (user_name == "" || user_name == null) {
		user_name = 'Test';
	}
}

function get_question_from_socket() {
	var selected_ans = $('input:radio[name=answer]:checked').val();
	var correctly_answered = false;
	if (typeof(selected_ans) != "undefined" && selected_ans != "")
		correctly_answered = selected_ans == $('.question .correct_answer').html()
	params = {
		game_id: game_id,
		users_data: users_data,
		question_count: question_count,
		self_user_id: self_user_id,
		correctly_answered: correctly_answered
	}
	send_message('get_question', params);
}

function response_get_question(data) {

	if (question_count == (max_question_count)) {
		send_message('final_scores', {
			game_id: game_id,
			question_count: question_count
		})
	} else {
		current_question = data;
		set_question(current_question);
	}
}


function set_question(question) {
	$('.question').css('display', 'block');
	$('.waiting-container').css('display', 'none');
	question_count = current_question.question_count;
	var possible_answers_str = '';
	//<input type="radio" name="sex" value="male">Male<br>
	$.each(question.options, function(index, value) {
		possible_answers_str += "<div class='possible_answer_container'><input type='radio' class='possible_answer' name='answer' value='" + index + "' id='" + index + "'/><label class='inline-block-element' for=" + index + ">" + value + "</label></div>"
	})
	users_data = question.users_data
	game_data = question.game_data
	if(game_id == null || game_id == "")
		game_id = question.game_id
	var random_colors = ['#C78989', '#89C7BA', '#B389C7', '#89AFC7', '#BFC789', '#C789A7'];
	$('.question .user-profile-image.user-1').css('background', random_colors[Math.floor((Math.random() * 10))]);
	$('.question .user-profile-image.user-2').css('background', random_colors[Math.floor((Math.random() * 10))]);
	$('.question .user-name.user-1').html(users_data['1'].name);
	$('.question .user-name.user-2').html(users_data['2'].name);

	$($('.question .text')[0]).html(question_count + ". " + question.question + ' (' + selected_genre + ')');
	$($('.question .song')[0]).html(question.song);
	$($('.question .possible_answers')[0]).html(possible_answers_str);
	$($('.question .correct_answer')[0]).html(question.answer);
	$($('.question .song-waveform-image')[0]).attr('src', question.waveform);
	$($('.question .score')[0]).html(question.users_data['1'].score * 10);
	$($('.question .score')[1]).html(question.users_data['2'].score * 10);
	$($('.progress-bar-status .user-1')).css('height', (question.users_data['1'].score) / 100 * 160);
	$($('.progress-bar-status .user-2')).css('height', (question.users_data['2'].score) / 100 * 160);
	users_data_str = '';
	for (i in users_data) {
		users_data_str += "NAME: " + users_data[i].name + ".... SCORE: " + users_data[i].score + "\n"
	}
	console.log(users_data_str);
	$($('.question .users_data')[0]).html(users_data_str);
	$('.question').show();
	if (typeof(mySound) != "undefined")
		mySound.destruct()
	mySound = soundManager.createSound({
		id: question_count,
		url: question.song,

		whileplaying: function() {
			$('.song-waveform-progress').css('width', ((this.position / this.duration) * 100) + "%");
		}
	});
	mySound.play();

	$('.question .possible_answers .possible_answer').unbind();
	$('.question .possible_answers .possible_answer').change(function() {
		// soundManager.stop(question_count);
		// soundManager.destroySound(question_count);
		mySound.destruct()
		// soundManager.stopAll()

		get_question_from_socket()
	})
	//$('.question .text')
}


function response_final_scores(data) {
	users_data = data;
	if (typeof(mySound) != "undefined")
		mySound.destruct();
	$('.question').css('display', 'none');
	$('.final-score').css('display', 'block');
	if (users_data[1].score > users_data[2].score) {
		$('.final-score-verdict').html(users_data[1].name + " wins!")
	} else if (users_data[1].score < users_data[2].score) {
		$('.final-score-verdict').html(users_data[2].name + " wins!")
	} else {
		$('final-score-verdict').html("It's a tie!")
	}
	$('.final-score .user-name.user-1').html(users_data[1].name);
	$('.final-score .user-name.user-2').html(users_data[2].name);
	$($('.final-score .score')[0]).html(users_data[1].score * 10);
	$($('.final-score .score')[1]).html(users_data[2].score * 10);
}