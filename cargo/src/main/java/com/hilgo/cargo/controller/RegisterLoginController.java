package com.hilgo.cargo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.hilgo.cargo.request.LoginRequest;
import com.hilgo.cargo.request.RegisterRequest;
import com.hilgo.cargo.request.SetPasswordRequest;
import com.hilgo.cargo.request.VerifyUserRequest;
import com.hilgo.cargo.response.LoginResponse;
import com.hilgo.cargo.response.RegisterResponse;
import com.hilgo.cargo.service.RegisterLoginService;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.entity.User;


import lombok.RequiredArgsConstructor;


@Controller
@RequiredArgsConstructor
@RequestMapping("/auth")
public class RegisterLoginController {

	private final RegisterLoginService registerLoginService;
	private final UserRepository	userRepository;

	@PostMapping(path = "/register")
	public ResponseEntity<RegisterResponse> register(@RequestBody RegisterRequest registerRequest)
	{
		return ResponseEntity.ok(registerLoginService.register(registerRequest));
	}

	@PostMapping(path = "/verify")
	public ResponseEntity<?> verifyUser(@RequestBody VerifyUserRequest verifyUserRequest) {
		try {
			registerLoginService.verifyUser(verifyUserRequest);
			return ResponseEntity.ok("Kullanıcı başarıyla doğrulandı.");
		} catch (RuntimeException e) {
			return ResponseEntity.badRequest().body(e.getMessage());
		}
	}

	@PostMapping(path = "/login")
	public ResponseEntity<LoginResponse> auth(@RequestBody LoginRequest loginRequest)
	{
		return ResponseEntity.ok(registerLoginService.auth(loginRequest));
	}

	@PostMapping(path = "/logoutt")
	public ResponseEntity<String> logout()
	{
		return ResponseEntity.ok(registerLoginService.logout());
	}

	@PostMapping(path = "/forgot")
	public ResponseEntity<String> forgotPassword(@RequestParam String email){
		return ResponseEntity.ok(registerLoginService.forgotPassword(email));
	}

	@PostMapping(path = "/change")
	public ResponseEntity<String> changePasswprd(@RequestParam String email){
		return ResponseEntity.ok(registerLoginService.changePassword(email));
	}

	@PutMapping(path = "/setPassword")
	public ResponseEntity<String> setPassword(@RequestParam String token, @RequestBody SetPasswordRequest setPasswordRequest) {
	User user = userRepository.findByMail(setPasswordRequest.getEmail).orElseThrow(() -> new RuntimeException("User not found!"));
    boolean tokenValid = isTokenValid(token, user);
    if (tokenValid) {
        // Token geçerli ise, şifreyi değiştir
        boolean passwordChanged = registerLoginService.changePassword(setPasswordRequest);
        if (passwordChanged) {
            return ResponseEntity.ok("Password successfully updated.");
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to update password.");
        }
    } else {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired reset token.");
    }
}
}
