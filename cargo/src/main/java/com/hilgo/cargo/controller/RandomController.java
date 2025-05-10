package com.hilgo.cargo.controller;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/random")
public class RandomController {

	@GetMapping
	public String random()
	{
		return SecurityContextHolder.getContext().getAuthentication().getName();
	}
}
