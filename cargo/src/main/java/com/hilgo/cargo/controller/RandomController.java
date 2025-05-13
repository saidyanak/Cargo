package com.hilgo.cargo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/random")
public class RandomController {

	@GetMapping
	public ResponseEntity<Map<String, String>> random() {
    String userName = SecurityContextHolder.getContext().getAuthentication().getName();
    Map<String, String> response = new HashMap<>();
    response.put("name", userName);
    return ResponseEntity.ok(response);
	}
}
