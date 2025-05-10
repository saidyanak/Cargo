package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Distributor;
import com.hilgo.cargo.entity.Driver;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.repository.DriverRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.RegisterRequest;
import com.hilgo.cargo.response.RegisterResponse;
import com.hilgo.cargo.response.UserResponse;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RegisterLoginService {

	private final UserRepository userRepository;
	private final PasswordEncoder passwordEncoder;
	//private final JwtService jwtService;
	//private final AuthenticationManager authenticationManager;
	private final DriverRepository diDriverRepository;
	private final JavaMailSender mailSender;

	private String generateVerificationCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}
	
	public RegisterResponse register(RegisterRequest request) {

		User user;
		Optional<User> existingUserByEmail = userRepository.findByMail(request.getMail());
		if (existingUserByEmail.isPresent()) {
			throw new RuntimeException("Bu e-posta adresi ile kayıtlı bir kullanıcı zaten var.");
		}

		Optional<User> existingUserByUsername = userRepository.findByUsername(request.getUserName());
		if (existingUserByUsername.isPresent()) {
			throw new RuntimeException("Bu kullanıcı adı ile kayıtlı bir kullanıcı zaten var.");
		}

		Optional<User> existingUserByPhoneNumber = userRepository.findByPhoneNumber(request.getPhoneNumber());
		if (existingUserByPhoneNumber.isPresent()) {
			throw new RuntimeException("Bu telefon numarası ile kayıtlı bir kullanıcı zaten var.");
		}

		if (request.getRole().toString() == "DISTRIBUTOR") {
			user = new Distributor();
		}
		else {
			user = new Driver();
		}
		
		user.setMail(request.getMail());
		user.setUsername(request.getUserName());
		user.setPassword(passwordEncoder.encode(request.getPassword()));
		user.setPhoneNumber(request.getPhoneNumber());
		user.setRoles(request.getRole());
		user.setVerificationCode(generateVerificationCode());
		user.setVerificationCodeExpiresAt(LocalDateTime.now().plusDays(2));
		user.setEnable(false);
		
		userRepository.save(user);
		
		sendVerificationCode(user);

		return new RegisterResponse(new UserResponse(user.getUsername(), user.getMail(), user.getRoles()));
	}

	private void sendVerificationCode(User user) {
		MimeMessage mimeMessage = mailSender.createMimeMessage();

		try {
			MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");

			helper.setTo(user.getMail());
			helper.setSubject("🎉 Kayıt Başarılı! Hoş Geldiniz, " + user.getUsername());

			String htmlContent = "<!DOCTYPE html>" + "<html>"
					+ "<body style='font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9;'>"
					+ "<div style='background-color: #ffffff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px #ccc;'>"
					+ "<h2 style='color: #2c3e50;'>Hoş Geldiniz, <strong>" + user.getUsername() + "</strong> 👋</h2>"
					+ "<p>Sisteme başarılı bir şekilde kayıt oldunuz. Tüm hizmetlerimizi almadan önce doğrulama kodunu girmeniz gerekiyor Doğrulama konuduz</p>"+ user.getVerificationCode()
					+ "<p style='color: #27ae60;'><strong>Teşekkür ederiz,</strong></p>" + "<p><i>Hilgo Yazılım</i></p>"
					+ "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' alt='Success Icon' style='width: 100px; margin-top: 20px;'/>"
					+ "</div>" + "</body>" + "</html>";

			helper.setText(htmlContent, true); // true = HTML içeriği destekle
			mailSender.send(mimeMessage);

		} catch (MessagingException e) {
			throw new RuntimeException("Mail gönderilirken hata oluştu", e);
		}
	}

}
