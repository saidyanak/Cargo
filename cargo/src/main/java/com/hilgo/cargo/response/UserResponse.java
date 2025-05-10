package com.hilgo.cargo.response;


import com.hilgo.cargo.entity.enums.Roles;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class UserResponse {

	private String username;
	private String email;
	private Roles role;
}
