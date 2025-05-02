package com.hilgo.cargo.service;

import java.util.Optional;

import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.LoginRequest;
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
	private final JwtService jwtService;
	private final AuthenticationManager authenticationManager;
	private final JavaMailSender mailSender;

	public RegisterResponse register(RegisterRequest request) {
	    // Aynı e-posta ile kayıt kontrolü
	    Optional<User> existingUserByEmail = userRepository.findByMail(request.getMail());
	    if (existingUserByEmail.isPresent()) {
	        throw new RuntimeException("Bu e-posta adresi ile kayıtlı bir kullanıcı zaten var.");
	    }

	    // Aynı kullanıcı adı ile kayıt kontrolü
	    Optional<User> existingUserByUsername = userRepository.findByUsername(request.getUserName());
	    if (existingUserByUsername.isPresent()) {
	        throw new RuntimeException("Bu kullanıcı adı ile kayıtlı bir kullanıcı zaten var.");
	    }

	    // Aynı telefon numarası ile kayıt kontrolü
	    Optional<User> existingUserByPhoneNumber = userRepository.findByPhoneNumber(request.getPhoneNumber());
	    if (existingUserByPhoneNumber.isPresent()) {
	        throw new RuntimeException("Bu telefon numarası ile kayıtlı bir kullanıcı zaten var.");
	    }

	    // Yeni kullanıcı oluşturma
	    User user = new User();
	    user.setMail(request.getMail());
	    user.setUsername(request.getUserName());
	    user.setPassword(passwordEncoder.encode(request.getPassword()));
	    user.setPhoneNumber(request.getPhoneNumber());
	    user.setRoles(request.getRole());

	    userRepository.save(user);

	    // JWT Token oluştur
	    String jwtToken = jwtService.generateToken(user);

	    // Kullanıcıya e-posta gönder
	    sendWelcomeEmail(user.getMail(), user.getUsername());

	    return new RegisterResponse(jwtToken, new UserResponse(user.getUsername(), user.getMail(), user.getRoles()));
	}

	public RegisterResponse auth(LoginRequest request) {
		try {
			authenticationManager.authenticate(
					new UsernamePasswordAuthenticationToken(request.getUserName(), request.getPassword()));
		} catch (Exception e) {
			throw new RuntimeException("Kullanıcı adı veya şifre hatalı.");
		}

		User user = userRepository.findByUsername(request.getUserName())
				.orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + request.getUserName()));

		String jwtToken = jwtService.generateToken(user);
		return new RegisterResponse(jwtToken, new UserResponse(user.getUsername(), user.getMail(), user.getRoles()));

	}

	private void sendWelcomeEmail(String to, String username) {
	    MimeMessage mimeMessage = mailSender.createMimeMessage();

	    try {
	        MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");

	        helper.setTo(to);
	        helper.setSubject("🎉 Kayıt Başarılı! Hoş Geldiniz, " + username);

	        String htmlContent = "<!DOCTYPE html>" +
	                "<html>" +
	                "<body style='font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9;'>" +
	                "<div style='background-color: #ffffff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px #ccc;'>" +
	                "<h2 style='color: #2c3e50;'>Hoş Geldiniz, <strong>" + username + "</strong> 👋</h2>" +
	                "<p>Sisteme başarılı bir şekilde kayıt oldunuz. Artık tüm hizmetlerimizi kullanmaya başlayabilirsiniz!</p>" +
	                "<p style='color: #27ae60;'><strong>Teşekkür ederiz,</strong></p>" +
	                "<p><i>Hilgo Yazılım</i></p>" +
	                "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' alt='Success Icon' style='width: 100px; margin-top: 20px;'/>" +
	                "</div>" +
	                "</body>" +
	                "</html>";

	        helper.setText(htmlContent, true); // true = HTML içeriği destekle
	        mailSender.send(mimeMessage);

	    } catch (MessagingException e) {
	        throw new RuntimeException("Mail gönderilirken hata oluştu", e);
	    }
	}

}
