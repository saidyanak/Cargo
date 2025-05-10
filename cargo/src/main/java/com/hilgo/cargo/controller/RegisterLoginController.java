package com.hilgo.cargo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import com.hilgo.cargo.request.RegisterRequest;
import com.hilgo.cargo.response.RegisterResponse;
import com.hilgo.cargo.service.RegisterLoginService;

import lombok.RequiredArgsConstructor;


@Controller
@RequiredArgsConstructor
@RequestMapping("/auth")
public class RegisterLoginController {
	
	private final RegisterLoginService registerLoginService;
	
	@PostMapping(path = "/register")
	public ResponseEntity<RegisterResponse> register(@RequestBody RegisterRequest registerRequest)
	{
		return ResponseEntity.ok(registerLoginService.register(registerRequest));
	}
	
}
