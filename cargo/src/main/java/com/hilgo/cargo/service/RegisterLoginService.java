package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Distributor;
import com.hilgo.cargo.entity.Driver;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.repository.DistributorRepository;
import com.hilgo.cargo.repository.DriverRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.LoginRequest;
import com.hilgo.cargo.request.RegisterRequest;
import com.hilgo.cargo.request.SetPasswordRequest;
import com.hilgo.cargo.request.VerifyUserRequest;
import com.hilgo.cargo.response.LoginResponse;
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
	private final AuthenticationManager authenticationManager;
	private final JavaMailSender mailSender;
	private final JwtService jwtService;
	private final DriverRepository driverRepository;
	private final DistributorRepository distributorRepository;


	private String generateVerificationCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}

	public RegisterResponse distributorRegister(RegisterRequest request)
	{
		User user;
		Optional<Distributor> existingUserByVkn = distributorRepository.findByVkn(request.getTcOrVkn());
		if (existingUserByVkn.isPresent()) {
			throw new RuntimeException("Bu Vkn ile kayıtlı bir kullanıcı zaten var.");
		}
		user = new Distributor(request.getTcOrVkn(), null, null);
		user.setMail(request.getMail());
		user.setUsername(request.getUsername());
		user.setPassword(passwordEncoder.encode(request.getPassword()));
		user.setPhoneNumber(request.getPhoneNumber());
		user.setRoles(request.getRole());
		user.setVerificationCode(generateVerificationCode());
		user.setVerificationCodeExpiresAt(LocalDateTime.now().plusHours(2));
		user.setEnable(false);
		userRepository.save(user);
		sendVerificationCode(user);
		System.out.println("Asenkron iş dondü.");
		return new RegisterResponse(new UserResponse(request.getTcOrVkn(), user.getUsername(), user.getMail(), user.getRoles()));
	}

	public RegisterResponse driverRegister(RegisterRequest request)
	{
		User user;
		Optional<Driver> existingUserTc = driverRepository.findByTc(request.getTcOrVkn());
		if (existingUserTc.isPresent()) {
			throw new RuntimeException("Bu Tc ile kayıtlı bir kullanıcı zaten var.");
		}
		user = new Driver(request.getTcOrVkn(), null, null, null);
		user.setMail(request.getMail());
		user.setUsername(request.getUsername());
		user.setPassword(passwordEncoder.encode(request.getPassword()));
		user.setPhoneNumber(request.getPhoneNumber());
		user.setRoles(request.getRole());
		user.setVerificationCode(generateVerificationCode());
		user.setVerificationCodeExpiresAt(LocalDateTime.now().plusHours(2));
		user.setEnable(false);
		userRepository.save(user);
		sendVerificationCode(user);
		System.out.println("Asenkron iş dondü.");
		return new RegisterResponse(new UserResponse(request.getTcOrVkn(), user.getUsername(), user.getMail(), user.getRoles()));
	}

	public RegisterResponse register(RegisterRequest request) {
		Optional<User> existingUserByEmail = userRepository.findByMail(request.getMail());
		if (existingUserByEmail.isPresent()) {
			throw new RuntimeException("Bu e-posta adresi ile kayıtlı bir kullanıcı zaten var.");
		}
		Optional<User> existingUserByUsername = userRepository.findByUsername(request.getUsername());
		if (existingUserByUsername.isPresent()) {
			throw new RuntimeException("Bu kullanıcı adı ile kayıtlı bir kullanıcı zaten var.");
		}
		Optional<User> existingUserByPhoneNumber = userRepository.findByPhoneNumber(request.getPhoneNumber());
		if (existingUserByPhoneNumber.isPresent()) {
			throw new RuntimeException("Bu telefon numarası ile kayıtlı bir kullanıcı zaten var.");
		}
		if (request.getRole().toString() == "DISTRIBUTOR") {
			return (distributorRegister(request));
		}
		else {
			return (driverRegister(request));
		}
	}

	@Async
	private void sendVerificationCode(User user) {
		MimeMessage mimeMessage = mailSender.createMimeMessage();

		    System.out.println("Asenkron iş başladı.");
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
		    System.out.println("Asenkron iş bitti.");

	}

	private void sendVerificationEmail(User user, String passwordCode) {
		MimeMessage mimeMessage = mailSender.createMimeMessage();

		try {
			MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");

			helper.setTo(user.getMail());
			helper.setSubject("🎉 Şifre Oluşturma, " + user.getUsername());

			String htmlContent = "<!DOCTYPE html>" + "<html>"
					+ "<body style='font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9;'>"
					+ "<div style='background-color: #ffffff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px #ccc;'>"
					+ "<h2 style='color: #2c3e50;'>Hoş Geldiniz, <strong>" + user.getUsername() + "</strong> 👋</h2>"
					+ "Doğrulama konuduz</p>"+ passwordCode
					+ "<p style='color: #27ae60;'><strong>Teşekkür ederiz,</strong></p>" + "<p><i>Hilgo Yazılım</i></p>"
					+ "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' alt='Success Icon' style='width: 100px; margin-top: 20px;'/>"
					+ "</div>" + "</body>" + "</html>";

			helper.setText(htmlContent, true); // true = HTML içeriği destekle
			mailSender.send(mimeMessage);

		} catch (MessagingException e) {
			throw new RuntimeException("Mail gönderilirken hata oluştu", e);
		}
	}


	public LoginResponse auth(LoginRequest loginRequest) {
		User user = userRepository.findByUsername(loginRequest.getUsername())
				.orElseThrow(() -> new RuntimeException("User not found!"));
		if (!user.isEnable()) {
			throw new RuntimeException("Hesap Doğrulanmadı!");
		}else {
			authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword()));
			UserResponse userResponse = new UserResponse(null, user.getUsername(), user.getEmail(), user.getRoles());
			String token = jwtService.generateToken(user);
			user.setActive(true);
			userRepository.save(user);
			return LoginResponse.builder()
					.token(token)
					.userResponse(userResponse)
					.build();
		}

	}


	public void verifyUser(VerifyUserRequest verifyUserRequest) {
		User user = userRepository.findByMail(verifyUserRequest.getEmail())
				.orElseThrow(() -> new RuntimeException("User not found!"));
		if (user.getVerificationCodeExpiresAt().isBefore(LocalDateTime.now())) {
			throw new RuntimeException("Doğrulama Kodunun Süresi Doldu!");
		}
		if (user.getVerificationCode().equals(verifyUserRequest.getVerificationCode())) {
			user.setEnable(true);
			user.setVerificationCodeExpiresAt(LocalDateTime.now().plusDays(2));
			userRepository.save(user);
		}else {
			throw new RuntimeException("Doğrulama Kodu Hatalı!");
		}
	}

	public String forgotPassword(String email) {
		User user = userRepository.findByMail(email).orElseThrow(() -> new RuntimeException("User not found!"));
		String token = jwtService.generateToken(user);
		String link = "http://localhost:8000/reset-password?token=" + token;
		sendVerificationEmail(user, link);
		return "E-mail'inizi kontrol edin.";
	}

	public String changePassword(String email) {
		User user = userRepository.findByMail(email).orElseThrow(() -> new RuntimeException("User not found!"));
		String passwordCode = generateVerificationCode();
		user.setVerificationCode(passwordCode);
		userRepository.save(user);

		try {
			sendVerificationEmail(user, passwordCode);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return "E-mail'inizi kontrol edin.";
	}

	public boolean setPassword(SetPasswordRequest setPasswordRequest) {
		User user = userRepository.findByMail(setPasswordRequest.getEmail()).orElseThrow(() -> new RuntimeException("User not found"));
		if (setPasswordRequest.getPassword().equals(setPasswordRequest.getCheckPassword())) {
			user.setPassword(passwordEncoder.encode(setPasswordRequest.getCheckPassword()));
			user.setVerificationCode(null);
			userRepository.save(user);
			return true;
		}else {
			throw new RuntimeException("Şifreler Aynı Değil!");
		}
	}

    public String logout() {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() ->
		new RuntimeException("User not found"));
		user.setActive(false);
		userRepository.save(user);
        return ("Logout");
	}
}
