package com.hilgo.cargo.response;


import com.hilgo.cargo.entity.enums.Roles;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class UserResponse {

	private String tcOrVkn;
	private String username;
	private String email;
	private Roles role;
}
